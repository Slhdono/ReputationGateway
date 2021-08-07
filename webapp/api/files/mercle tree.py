from merkletools import MerkleTools
import json
import os
import sys
import requests
token = '123456791'

f = open(os.path.join(sys.path[0], "Dynamic Reputation.json"), "r")

json_data = json.load(f)

mt = MerkleTools()
for user_dr in json_data:
    address = user_dr['address']
    dr = user_dr['DR']
    timer = user_dr['timer']
    mt.add_leaf(f'{address}/{dr}/{timer}', True)
mt.make_tree()
if mt.is_ready:
    root_value = mt.get_merkle_root()

print('sending ...')
a = requests.post('http://127.0.0.1:8000/api/root_hash', {"root_hash":root_value, "sender_token":token})
print(a.content)
print(a)