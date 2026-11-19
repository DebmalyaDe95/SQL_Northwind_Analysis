from __future__ import annotations
import csv, json, re, sqlite3
from pathlib import Path
ROOT=Path(__file__).resolve().parent
DB=ROOT/'data'/'northwind.db'
SQL=ROOT/'queries.sql'
OUT=ROOT/'results'

def main():
    OUT.mkdir(exist_ok=True)
    text=SQL.read_text(encoding='utf-8')
    blocks=re.findall(r'-- Q(\d+): ([^\n]+)\n(.*?)-- END Q\1',text,re.S)
    conn=sqlite3.connect(f'file:{DB.as_posix()}?mode=ro',uri=True)
    summaries=[]
    try:
        for number,question,query in blocks:
            cur=conn.execute(query.strip())
            rows=cur.fetchall(); columns=[d[0] for d in cur.description]
            path=OUT/f'Q{int(number):02d}_results.csv'
            with path.open('w',newline='',encoding='utf-8-sig') as f:
                w=csv.writer(f); w.writerow(columns); w.writerows(rows)
            summaries.append({'question_number':int(number),'question':question,'rows_returned':len(rows),'result_file':path.name,'columns':columns})
    finally: conn.close()
    (OUT/'query_run_summary.json').write_text(json.dumps(summaries,indent=2),encoding='utf-8')
    print(json.dumps(summaries,indent=2))
if __name__=='__main__': main()
