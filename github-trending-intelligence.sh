#!/usr/bin/env python3
"""
GitHub Trending Intelligence v7 - 极速版
优化：去全量PR查询，改为轻量搜索+精准PR补充top N
"""
import argparse, json, os, sys, time, math, urllib.request
from datetime import datetime, timezone

GITHUB_TOKEN = os.environ.get('GITHUB_TOKEN', '')
APP_ID = 'BnnCb1hmVaoXHIsaJyPcJyIgnRh'
PROJECT_TABLE = 'tbl79lXTvHT5olCl'
SUMMARY_TABLE = 'tblcc9QHGngiacVe'
ALERT_TABLE = 'tblePYbnfUAxuU9P'
RANK_TABLE = 'tbl1hGJ02OWB7fvh'

def gh(url):
    h = {'User-Agent': 'taizi-v7', 'Accept': 'application/vnd.github.v3+json'}
    if GITHUB_TOKEN: h['Authorization'] = f'token {GITHUB_TOKEN}'
    req = urllib.request.Request(url, headers=h)
    try:
        with urllib.request.urlopen(req, timeout=15) as r: return json.loads(r.read())
    except: return {}

def ft():
    with open('/root/.openclaw/openclaw.json') as f:
        c = json.load(f)
    req = urllib.request.Request('https://open.feishu.cn/open-apis/auth/v3/app_access_token/internal',
        data=json.dumps({'app_id': c['channels']['feishu']['appId'], 'app_secret': c['channels']['feishu']['appSecret']}).encode(),
        headers={'Content-Type': 'application/json'})
    with urllib.request.urlopen(req) as r: return json.loads(r.read())['app_access_token']

def bw(t, tbl, recs):
    url = f'https://open.feishu.cn/open-apis/bitable/v1/apps/{APP_ID}/tables/{tbl}/records/batch_create'
    req = urllib.request.Request(url, data=json.dumps({'records': recs}).encode(),
        headers={'Content-Type': 'application/json', 'Authorization': f'Bearer {t}'})
    try:
        with urllib.request.urlopen(req) as r: return json.loads(r.read()).get('code') == 0
    except: return False

def del_all(t, tbl):
    while True:
        req = urllib.request.Request(f'https://open.feishu.cn/open-apis/bitable/v1/apps/{APP_ID}/tables/{tbl}/records?page_size=100',
            headers={'Authorization': f'Bearer {t}'})
        with urllib.request.urlopen(req) as r: items = json.loads(r.read()).get('data', {}).get('items', [])
        if not items: break
        ids = [r['record_id'] for r in items]
        for i in range(0, len(ids), 10):
            dr = urllib.request.Request(f'https://open.feishu.cn/open-apis/bitable/v1/apps/{APP_ID}/tables/{tbl}/records/batch_delete',
                data=json.dumps({'records': ids[i:i+10]}).encode(),
                headers={'Content-Type': 'application/json', 'Authorization': f'Bearer {t}'})
            try: urllib.request.urlopen(dr)
            except: pass
            time.sleep(0.2)

def pr_stats(name):
    d = gh(f'https://api.github.com/repos/{name}/pulls?state=closed&per_page=1&sort=updated')
    if not d: return 0, 0, 0
    now = datetime.now(timezone.utc)
    merged = sum(1 for p in d[:30] if p.get('merged_at'))
    recent = sum(1 for p in d[:30] if p.get('created_at') and (now - datetime.fromisoformat(p['created_at'].replace('Z','+00:00'))).days <= 30)
    return merged, recent, round(recent * merged / max(len(d[:30]), 1), 2)

def light_analyze(repo):
    s, f = repo.get('stargazers_count', 0), repo.get('forks_count', 0)
    age = max(1, (datetime.now(timezone.utc) - datetime.fromisoformat(repo.get('created_at','2024-01-01').replace('Z','+00:00'))).days)
    vr = s / age
    if age < 7: vr *= 0.7
    fr = f / max(s, 1)
    cs = min(fr*100, 40) + min(repo.get('open_issues_count',0)*2, 20) + min(max(1,repo.get('open_issues_count',0)//2)*3,20) + (5 if age<7 else 10 if age<30 else 15 if age<180 else 20)
    nm = repo.get('full_name','').lower()
    dc = (nm + ' ' + (repo.get('description') or '') + ' ' + ' '.join(repo.get('topics',[])) + ' ' + (repo.get('language') or '')).lower()
    ai = sum(1 for k in ['agent','llm','gpt',' ai ','claude','openai','langchain','chatbot','assistant','rag','vector','embedding','agentic','autonomous','multi-agent','swarm','crew','mcp','ollama','nvidia','claw','openclaw','anthropic'] if k in dc)
    if 'openclaw' in nm or 'claw' in nm: ai += 3
    mcp = sum(1 for k in ['mcp','tool','plugin','integration','connector','browser'] if k in dc)
    sk = sum(1 for k in ['cli','tool','utility','wrapper','sdk','library','bot','skill','prompt'] if k in dc)
    cat = 'OpenClaw' if 'openclaw' in nm or ('claw' in nm and ai>=2) else 'AI/Agent' if ai>=5 else 'MCP/Tools' if ai>=2 and mcp>=1 else 'Tool/Skill' if sk>=3 else (((repo.get('topics') or [''])[0] or 'Other'))
    comprehensive = vr * (min(cs,100)/100) * (1+ai*0.05) * (1+math.log10(max(s,1))*0.1)
    return {'name': repo['full_name'], 'stars': s, 'forks': f, 'velocity': round(vr,2), 'cred_v4': min(cs,100), 'pr_cred': 0, 'total_cred': round(min(cs,100)*0.8,1),
            'merged_prs': 0, 'recent_prs': 0, 'pr_activity': 0, 'comprehensive': round(comprehensive,2),
            'ai_score': ai, 'mcp_score': mcp, 'skill_score': sk, 'category': cat,
            'created_at': repo.get('created_at','')[:10], 'age_days': age, 'language': repo.get('language',''),
            'description': repo.get('description',''), 'topics': repo.get('topics',[])[:5], 'url': repo.get('html_url','')}

def enrich(r):
    m, rc, pa = pr_stats(r['name'])
    pcs = 20 if m>=100 else 15 if m>=50 else 10 if m>=20 else 5 if m>=5 else 0
    prs = min(rc*2, 20)
    pc = min(40, pcs+prs)
    tc = round(r['cred_v4']*0.6+pc*0.4, 1)
    ab = 1+r['ai_score']*0.05
    comp = r['velocity']*(tc/100)*ab*(1+math.log10(max(r['stars'],1))*0.1)
    r.update({'pr_cred': pc, 'total_cred': tc, 'merged_prs': m, 'recent_prs': rc, 'pr_activity': pa, 'comprehensive': round(comp,2)})
    return r

def gi(r):
    n, d, c = r['name'].lower(), (r.get('description') or '').lower(), r.get('category','')
    if 'openclaw' in n or c=='OpenClaw':
        if 'nemo' in n: return "NVIDIA推出的OpenClaw官方插件，提供安全的OpenClaw安装体验，支持一键部署和配置管理。"
        elif 'autor' in n: return "基于OpenClaw的全自主科研AI Agent，能够自动规划和执行复杂研究任务。"
        elif 'team' in n: return "多Agent协作系统，模拟团队智能，通过多个AI Agent分工合作完成复杂任务。"
        elif 'nano' in n: return "香港大学开发的OpenClaw增强版，集成高级记忆系统和多模态理解能力。"
        elif 'zeroclaw' in n: return "Rust编写的高性能OpenClaw运行环境，更快的执行速度和更低的资源占用。"
        elif 'chatgpt-on-wechat' in n: return "让ChatGPT/Claude等AI接入微信的开源项目，支持多模型切换和群聊自动回复。"
        elif 'astron' in n or 'langbot' in n: return "功能丰富的AI机器人平台，支持多种AI模型接入和插件扩展。"
        else: return f"OpenClaw生态项目，{r.get('description','')[:60] if r.get('description') else '提供OpenClaw相关功能扩展。'}"
    if 'karpathy' in n: return "Karpathy推出的AI科研Agent，能够自主规划和执行研究实验，加速科学研究进程。"
    if 'browser-use' in n: return "让AI Agent控制浏览器的工具，能够自动化操作网页任务。"
    if 'dify' in n: return "开源LLM应用开发平台，支持可视化编排AI工作流，零代码构建AI应用。"
    if 'openhands' in n: return "开源AI Agent系统，能够自主操作电脑完成复杂软件工程任务。"
    if 'langchain' in n: return "LangChain的Python库，为LLM应用开发提供组件化的工具链支持。"
    return f"{r.get('description','')[:80] if r.get('description') else '开源AI工具项目。'}"

def analyze(repos, prev=None):
    a = {}
    s = {'total_repos': len(repos), 'total_stars': sum(r['stars'] for r in repos),
         'avg_velocity': round(sum(r['velocity'] for r in repos)/len(repos),2),
         'avg_credibility': round(sum(r['total_cred'] for r in repos)/len(repos),1),
         'openclaw_count': sum(1 for r in repos if r['category']=='OpenClaw'),
         'ai_agent_count': sum(1 for r in repos if r['category']=='AI/Agent'),
         'mcp_count': sum(1 for r in repos if r['category']=='MCP/Tools')}
    cd = {'🟢正常': sum(1 for r in repos if r['total_cred']>=60),
          '🟡需关注': sum(1 for r in repos if 30<=r['total_cred']<60),
          '🔴疑似刷量': sum(1 for r in repos if r['total_cred']<30)}
    alerts = [{'name':r['name'],'level':'🔴高危' if r['total_cred']<30 else '🟡关注',
               'velocity':r['velocity'],'cred':r['total_cred'],'category':r['category'],
               'url':r['url'],'reason':f"增速{r['velocity']}⭐/天，但可信度仅{r['total_cred']}分"}
              for r in repos if r['velocity']>200 and r['total_cred']<40][:10]
    new_entries = []
    if prev:
        pn = {r['name'] for r in prev}
        new_entries = [{'name':r['name'],'velocity':r['velocity'],'category':r['category'],'cred':r['total_cred']}
                     for r in repos if r['name'] not in pn][:10]
    rank_changes = []
    if prev:
        pr = {r['name']:i for i,r in enumerate(sorted(prev,key=lambda x:x['comprehensive'],reverse=True))}
        cr = {r['name']:i for i,r in enumerate(repos)}
        for r in repos:
            if r['name'] in pr:
                d = pr[r['name']]-cr[r['name']]
                if d!=0:
                    rank_changes.append({'name':r['name'],'direction':'↑' if d>0 else '↓','delta':abs(d),
                                        'prev_rank':pr[r['name']]+1,'curr_rank':cr[r['name']]+1,
                                        'velocity':r['velocity'],'cred':r['total_cred'],'category':r['category']})
    rank_changes.sort(key=lambda x:-x['delta'])
    a.update({'stats':s,'credibility_dist':cd,'alerts':alerts,'new_entries':new_entries,'rank_changes':rank_changes[:10],
              'top_velocity':[(r['name'],r['velocity'],r['total_cred'],r['category']) for r in sorted(repos,key=lambda x:x['velocity'],reverse=True)[:5]],
              'top_credibility':[(r['name'],r['total_cred'],r['velocity'],r['stars']) for r in sorted(repos,key=lambda x:x['total_cred'],reverse=True)[:5]],
              'top_openclaw':[(r['name'],r['velocity'],r['total_cred'],r['ai_score']) for r in sorted(repos,key=lambda x:(x['category']=='OpenClaw',x['comprehensive']),reverse=True) if r['category']=='OpenClaw'][:5]})
    return a

def report(a, now_str):
    s,cd = a['stats'], a['credibility_dist']
    l = [f"📊 GitHub Trending数据分析报告 | {now_str}", "",
         f"**基础统计** 项目总数:{s['total_repos']} | 总⭐:{s['total_stars']:,} | 平均增速:{s['avg_velocity']}⭐/天 | 平均可信度:{s['avg_credibility']}分", "",
         f"**可信度分布** 🟢正常:{cd['🟢正常']}个 | 🟡需关注:{cd['🟡需关注']}个 | 🔴疑似刷量:{cd['🔴疑似刷量']}个", ""]
    if a['alerts']: l += [f"**🚨 告警({len(a['alerts'])}个)**"] + [f"  {x['level']} {x['name']} | {x['reason']}" for x in a['alerts']] + [""]
    if a['new_entries']: l += [f"**🆕 新上榜({len(a['new_entries'])}个)**"] + [f"  {x['name']} | {x['velocity']}⭐/天 | {x['category']}" for x in a['new_entries'][:5]] + [""]
    if a['rank_changes']: l += [f"**📊 排名变化**"] + [f"  {x['direction']}{x['delta']} | {x['name']} | {x['velocity']}⭐/天" for x in a['rank_changes'][:5]] + [""]
    l += [f"**🏆 增速Top5**"] + [f"  #{i+1} {n} | {v}⭐/天 | 可信度{c} | {cat}" for i,(n,v,c,cat) in enumerate(a['top_velocity'])]
    return '\n'.join(l)

def write_all(t, repos, a):
    now_ms = int(datetime.now().timestamp()*1000)
    # 项目表
    print("  Writing repos...", file=sys.stderr)
    del_all(t, PROJECT_TABLE)
    time.sleep(0.2)
    batch = [{'fields': {'文本':r['name'],'Star增速(⭐/天)':str(r['velocity']),'Stars总数':str(r['stars']),
        '语言':r.get('language') or 'N/A','分类':r['category'],'AI指数':r['ai_score'],
        'Skill指数':r['skill_score'],'MCP指数':r['mcp_score'],'项目介绍':gi(r),
        '原始描述':r.get('description') or '','Topics':', '.join(r.get('topics',[])[:5]),
        '链接':r['url'],'创建时间':r.get('created_at',''),'更新时间':r.get('created_at',''),
        '数据维度':'AI/OpenClaw','可信度评分':r['total_cred'],'v4可信度':r['cred_v4'],
        'PR可信度':r['pr_cred'],'已合并PRs':r['merged_prs'],'近30天PRs':r['recent_prs'],
        'Fork数':r['forks'],'排名':i+1,'综合评分':r['comprehensive']}} for i,r in enumerate(repos)]
    for i in range(0, len(batch), 25):
        bw(t, PROJECT_TABLE, batch[i:i+25]); time.sleep(0.2)
    print(f"  {len(repos)} repos written", file=sys.stderr)
    # 统计摘要
    del_all(t, SUMMARY_TABLE); time.sleep(0.2)
    s,cd = a['stats'], a['credibility_dist']
    bw(t, SUMMARY_TABLE, [{'fields': {'摘要标题':f"GitHub热榜 {datetime.now().strftime('%m-%d %H:%M')}",
        '统计时间':now_ms,'项目总数':s['total_repos'],'总Stars':s['total_stars'],'平均增速':s['avg_velocity'],
        '平均可信度':s['avg_credibility'],'正常项目数':cd['🟢正常'],'需关注数':cd['🟡需关注'],
        '疑似刷量数':cd['🔴疑似刷量'],'OpenClaw项目数':s['openclaw_count'],
        'AIAgent项目数':s['ai_agent_count'],'MCP项目数':s['mcp_count'],
        '新上榜项目数':len(a['new_entries']),'告警项目数':len(a['alerts']),'记录类型':'统计摘要'}}])
    time.sleep(0.2); print("  Summary written", file=sys.stderr)
    # 告警
    if a['alerts']:
        del_all(t, ALERT_TABLE); time.sleep(0.2)
        bw(t, ALERT_TABLE, [{'fields': {'项目名称':x['name'],'告警级别':x['level'],'告警原因':x['reason'],
            'Star增速':x['velocity'],'可信度':x['cred'],'分类':x['category'],'GitHub链接':x['url'],
            '检测时间':now_ms,'处理状态':'待处理'}} for x in a['alerts']])
        time.sleep(0.2); print(f"  {len(a['alerts'])} alerts written", file=sys.stderr)
    # 排名变化
    if a['rank_changes']:
        del_all(t, RANK_TABLE); time.sleep(0.2)
        bw(t, RANK_TABLE, [{'fields': {'项目名称':x['name'],'变化方向':x['direction'],'变化位数':x['delta'],
            '上期排名':x['prev_rank'],'本期排名':x['curr_rank'],'Star增速':x['velocity'],
            '可信度':x['cred'],'分类':x['category'],'检测时间':now_ms}} for x in a['rank_changes']])
        time.sleep(0.2); print(f"  {len(a['rank_changes'])} rank changes written", file=sys.stderr)

def main():
    pa = argparse.ArgumentParser()
    pa.add_argument('--top', type=int, default=100)
    pa.add_argument('--format', choices=['markdown','json','report'], default='report')
    pa.add_argument('--prev', default='/tmp/github_prev.json')
    pa.add_argument('--nowrite', action='store_true')
    args = pa.parse_args()
    
    # 轻量搜索（无PR统计）
    print("  Searching repos (light mode)...", file=sys.stderr)
    import urllib.parse
    q = urllib.parse.quote('openclaw OR ai-agent OR llm OR gpt OR claude OR agent created:>2026-02-01 stars:>30')
    data = gh(f'https://api.github.com/search/repositories?q={q}&sort=stars&order=desc&per_page={args.top*2}')
    raw = data.get('items', []) if data else []
    repos = [light_analyze(r) for r in raw]
    repos.sort(key=lambda x: x['velocity'], reverse=True)
    repos = repos[:args.top]
    print(f"  {len(repos)} repos fetched, enriching PR stats...", file=sys.stderr)
    # 只对top N补充PR数据
    for i, r in enumerate(repos[:args.top]):
        enrich(r)
        if (i+1) % 5 == 0: print(f"    {i+1}/{len(repos[:args.top])} PR stats done", file=sys.stderr)
        time.sleep(0.1)
    for i, r in enumerate(repos): r['rank'] = i+1
    
    # 对比数据
    prev = None
    if args.prev:
        try:
            with open(args.prev) as f: prev = json.load(f).get('repos', [])
        except: pass
    
    analysis = analyze(repos, prev)
    now_str = datetime.now().strftime('%Y-%m-%d %H:%M')
    output = {'fetch_time': now_str, 'version': 'v7', 'repos': repos, 'analysis': analysis}
    
    if args.format == 'json':
        print(json.dumps(output, ensure_ascii=False, indent=2)); return
    
    if not args.nowrite:
        t = ft()
        write_all(t, repos, analysis)
        with open(args.prev, 'w') as f: json.dump(output, f, ensure_ascii=False)
    
    print(report(analysis, now_str))
    if args.format == 'markdown':
        for r in repos:
            sk = f"{r['stars']/1000:.1f}k" if r['stars']>=1000 else str(r['stars'])
            c = r['total_cred']; ci = 'Green' if c>=60 else 'Yellow' if c>=30 else 'Red'
            print(f"\n**#{r['rank']}** ⭐{sk}({r['velocity']}/day) {r['name']}")
            print(f"- [{r.get('language') or 'N/A'}] {r['category']} | Score:{r['comprehensive']} | Cred:{ci}:{c} | PRs:{r['merged_prs']}(+{r['recent_prs']}/30d)")
            print(f"- {gi(r)}")

if __name__ == '__main__': main()
