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
        const d2 = await fetchUrl("https://raw.githubusercontent.com/QingRex/LoonKissSurge/refs/heads/main/Surge/Beta/HTTPDNS%E6%8B%A6%E6%88%AA%E5%99%A8.beta.sgmodule");
        const d3 = await fetchUrl("https://yfamilys.com/plugin/adultraplus.plugin");
        
        let domains = new Set<string>();
        
        // Parse SGModule (Rule)
        const lines = (d1 + "\n" + d2 + "\n" + d3).split('\n');
        for (let line of lines) {
            line = line.trim();
            if (line.startsWith('#') || line === '') continue;
            
            // Format: DOMAIN-SUFFIX,ad.weibo.com,REJECT
            if (line.includes('DOMAIN-SUFFIX,') || line.includes('DOMAIN,')) {
                const parts = line.split(',');
                if (parts.length >= 3 && parts[2].includes('REJECT')) {
                    domains.add(parts[1]);
                }
            } else if (line.includes('DOMAIN-KEYWORD,')) {
                // Ignore keywords or convert to contains
            }
            
            // Format: URL Rewrite (Surge/Loon/adultraplus)
            // ^https?:\/\/.*(pdd).* reject
            if (line.includes(' reject-200') || line.includes(' reject') || line.includes(' reject-dict') || line.includes(' reject-img') || line.includes(' reject-array')) {
               const parts = line.split(' ');
               if(parts.length >= 2) {
                   domains.add(parts[0]); // store the regex
               }
            }
        }
        
        console.log("Extracted items:", domains.size);
        fs.writeFileSync('ad_rules.json', JSON.stringify(Array.from(domains), null, 2));
    } catch(e) {
        console.error(e);
    }
})();
