// Export platform PNGs from the GPT-derived SVG silhouette, preserving alpha.
const fs=require('node:fs');const path=require('node:path');const crypto=require('node:crypto');const sharp=require('sharp');
const root=path.resolve(__dirname,'..');
const audit=path.join(root,'docs/artwork/interface');
async function main(){
 const record=JSON.parse(fs.readFileSync(path.join(audit,'records/platformMark.json'),'utf8'));
 if(!record.ink_svg)throw Error('Native mark must first be traced to a silhouette SVG');
 const input=path.join(root,record.ink_svg);const exports=[];
 for(const [density,scale] of [['mdpi',1],['hdpi',1.5],['xhdpi',2],['xxhdpi',3],['xxxhdpi',4]]){
  for(const [name,size,body] of [['cineus_monochrome',108,66],['cineus_notification',24,24]]){
   const width=Math.round(size*scale),art=Math.round(body*scale);
   const {data,info}=await sharp(input).resize(art,art,{fit:'contain',background:{r:255,g:255,b:255,alpha:0}}).ensureAlpha().raw().toBuffer({resolveWithObject:true});
   if(info.channels!==4)throw Error('Expected RGBA');
   for(let i=0;i<data.length;i+=4){data[i]=255;data[i+1]=255;data[i+2]=255;}
   const before=Math.floor((width-art)/2),after=width-art-before;
   const bytes=await sharp(data,{raw:{width:art,height:art,channels:4}}).extend({top:before,left:before,bottom:after,right:after,background:{r:255,g:255,b:255,alpha:0}}).png().toBuffer();
   const file=`android/app/src/main/res/drawable-${density}/${name}.png`;
   fs.writeFileSync(path.join(root,file),bytes);
   exports.push({file,width,height:width,source_svg:record.ink_svg,source_png:record.source,source_sha256:record.source_sha256,sha256:crypto.createHash('sha256').update(bytes).digest('hex')});
  }
 }
 fs.writeFileSync(path.join(audit,'ANDROID_ICONS.json'),JSON.stringify(exports,null,2)+'\n');
 console.log(exports.length+' native white-alpha PNGs exported from the GPT-derived brand.');
}
main().catch(e=>{console.error(e);process.exitCode=1});
