import json
import schedule
import time

def job():
    with open('Dynamic Reputation.json', 'r+') as f:
        print('working ...!')
        data = json.load(f)
        for i in data:
            if i['timer'] == 1:
                i['timer'] = 90
                if i['DR'] != 0:
                    i['DR'] -= 0.5
            else:
                i['timer'] -= 1

        f.seek(0)        # <--- should reset file position to the beginning.
        json.dump(data, f, indent=4)
        f.truncate()     # remove remaining part

# schedule.every().day.at("18:45").do(job)
schedule.every(1).minutes.do(job)

while 1:
    schedule.run_pending()
    time.sleep(1)



