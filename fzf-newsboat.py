#!/usr/bin/env python

import os
import sqlite3
import subprocess
import webbrowser


def run_fzf(iterable):
    fzf_proc = subprocess.Popen(['fzf', '-m', '--layout=reverse-list'],
                                stdin=subprocess.PIPE,
                                stdout=subprocess.PIPE,
                                stderr=None)
    for title in iterable:
        fzf_proc.stdin.write(bytes(title, 'utf-8') + b'\n')
        fzf_proc.stdin.flush()
    fzf_proc.stdin.close()
    out = [i.decode('utf-8').strip() for i in fzf_proc.stdout.readlines()]
    return out


def main():
    home = os.getenv('HOME')
    conn = sqlite3.connect(f'{home}/.local/share/newsboat/cache.db')
    c = conn.cursor()
    sql = '''select a.id, a.title, a.url, b.title from rss_item as a
                 inner join rss_feed as b
                 on a.feedurl = b.rssurl
             where unread = 1
             order by pubDate desc;'''
    qry = c.execute(sql)

    feed_items = {f'{i[1]} - {i[3]}': {'id': i[0], 'url': i[2]} for i in qry}

    out = run_fzf(feed_items)

    for o in out:
        url = feed_items[o]['url']
        webbrowser.open(url)

        id = feed_items[o]['id']
        c.execute(f'update rss_item set unread = 0 where id = {id}')

    conn.commit()
    c.close()


if __name__ == '__main__':
    main()
