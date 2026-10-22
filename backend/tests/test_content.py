from dataclasses import replace
import hashlib
import json
from fastapi.testclient import TestClient
import pytest
from cineus_commerce.app import create_app
from cineus_commerce.content import ContentRelease
from cineus_commerce.security import unb64

def package(tmp_path):
    root=tmp_path/'content';(root/'assets').mkdir(parents=True)
    data=b'\x89PNG\r\n\x1a\n'+b'x'*50;digest=hashlib.sha256(data).hexdigest()
    (root/'assets'/digest).write_bytes(data)
    manifest={'schema':1,'revision':1,'min_catalog':3,'assets':[{'item':'demo','sha256':digest,'format':'png','bytes':len(data)}],'collections':[],'events':[],'club_cycles':{}}
    (root/'release.json').write_text(json.dumps(manifest))
    return root,digest,data

def test_signed_manifest_authenticated_hash_asset_and_range(settings,credentials,tmp_path):
    root,digest,data=package(tmp_path)
    app=create_app(replace(settings,content_directory=str(root)));client=TestClient(app)
    assert client.get('/v1/content').status_code==401
    assert client.post('/v1/identity',json=credentials).status_code==200
    headers={'authorization':'Bearer '+credentials['token']}
    result=client.get('/v1/content',headers=headers);assert result.status_code==200
    envelope=result.json();app.state.commerce.ledger.secrets.signer.public_key().verify(unb64(envelope['signature']),unb64(envelope['payload']))
    content=json.loads(unb64(envelope['payload']));assert content['audience']=='cineus.content.v1' and content['environment']=='sandbox'
    result=client.get('/v1/content/assets/'+digest,headers={**headers,'Range':'bytes=12-','If-Range':'"'+digest+'"'})
    assert result.status_code==206 and result.content==data[12:]
    assert result.headers['content-range']==f'bytes 12-{len(data)-1}/{len(data)}'
    assert client.get('/v1/content/assets/'+'a'*64,headers=headers).status_code==404
    (root/'assets'/digest).write_bytes(b'corrupt')
    with pytest.raises(ValueError):ContentRelease(str(root))

def test_content_disabled_without_configuration(settings,credentials):
    client=TestClient(create_app(settings));client.post('/v1/identity',json=credentials)
    assert client.get('/v1/content',headers={'authorization':'Bearer '+credentials['token']}).status_code==503

def test_release_refuses_path_instead_of_digest(tmp_path):
    root,_,_=package(tmp_path);file=root/'release.json';j=json.loads(file.read_text());j['assets'][0]['sha256']='../../secrets';file.write_text(json.dumps(j))
    with pytest.raises(ValueError):ContentRelease(str(root))

@pytest.mark.parametrize('minimum',[3,4,5,6])
def test_supported_catalog_versions_keep_verified_asset_bounds(tmp_path,minimum):
    root,digest,_=package(tmp_path)
    file=root/'release.json';manifest=json.loads(file.read_text())
    manifest['min_catalog']=minimum;file.write_text(json.dumps(manifest))
    release=ContentRelease(str(root))
    assert release.payload['min_catalog']==minimum and digest in release.files

@pytest.mark.parametrize('minimum',[True,0,7,'6'])
def test_future_or_untyped_catalog_versions_are_rejected(tmp_path,minimum):
    root,_,_=package(tmp_path)
    file=root/'release.json';manifest=json.loads(file.read_text())
    manifest['min_catalog']=minimum;file.write_text(json.dumps(manifest))
    with pytest.raises(ValueError):ContentRelease(str(root))
