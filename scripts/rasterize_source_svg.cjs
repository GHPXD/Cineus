// Rasterize an existing authorized source before tracing; no geometry authored.
const sharp=require('sharp');
sharp(process.argv[2]).resize({width:640}).png().toFile(process.argv[3])
  .catch(error=>{console.error(error);process.exitCode=1;});
