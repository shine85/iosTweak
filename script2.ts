import fs from 'fs';
import https from 'https';

async function fetchUrl(url: string) {
  return new Promise<string>((resolve, reject) => {
    https.get(url, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => resolve(data));
    }).on('error', reject);
  });
}

(async () => {
    try {
        const d1 = await fetchUrl("https://raw.githubusercontent.com/QingRex/LoonKissSurge/refs/heads/main/Surge/Beta/%E5%B9%BF%E5%91%8A%E5%B9%B3%E5%8F%B0%E6%8B%A6%E6%88%AA%E5%99%A8.beta.sgmodule");
        console.log("File 1 sample:");
        console.log(d1.split('\n').slice(0, 15).join('\n'));
        const d3 = await fetchUrl("https://yfamilys.com/plugin/adultraplus.plugin");
        console.log("======\nFile 3 sample:");
        console.log(d3.split('\n').slice(0, 15).join('\n'));
    } catch(e) {
        console.error(e);
    }
})();
