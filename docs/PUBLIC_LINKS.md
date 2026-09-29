# Cineus — Links públicos e compartilhamento

O codec de desafio continua compatível com `cineus://challenge/CIN-XXXX`.

Para ativar links HTTPS em uma release, compile com:

```bash
--dart-define=CINEUS_PUBLIC_BASE_URL=https://SEU_DOMINIO
```

Quando configurado, `ChallengeCode.linkFor` gera:

```text
https://SEU_DOMINIO/challenge/CIN-XXXX
```

O parser aceita HTTPS somente para a origem configurada. Links de outro domínio
são rejeitados.

## Pendências que exigem dados externos

### Android App Links

No domínio, publicar `/.well-known/assetlinks.json` com o package
`dev.cineus.cineus` e o SHA-256 do certificado de produção. Depois adicionar
intent-filter HTTPS com `android:autoVerify="true"`.

O fingerprint não pode ser inventado no repositório: ele depende da chave de
assinatura/Play App Signing real.

### iOS Universal Links

No domínio, publicar `/.well-known/apple-app-site-association` com o Team ID e
bundle `dev.cineus.cineus`, e adicionar o Associated Domains entitlement
`applinks:SEU_DOMINIO`.

O Team ID depende da conta Apple Developer real.

### Web

A rota `/challenge/CIN-XXXX` deve servir a aplicação/landing page. Sem o app,
essa página pode encaminhar às lojas; com associação válida, o sistema abre o
aplicativo.

Até esses arquivos externos existirem, mantenha
`CINEUS_PUBLIC_BASE_URL` vazio: o app cai com segurança para o custom scheme.
