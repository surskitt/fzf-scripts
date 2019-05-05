#!/usr/bin/env python

import argparse
import os
import time
import sys
import signal

import ueberzug.lib.v0 as ueberzug


def get_opts():
    parser = argparse.ArgumentParser(description='display image on terminal')
    rungroup = parser.add_mutually_exclusive_group()

    parser.add_argument('--img', '-i',
                        help='images to display')
    parser.add_argument('--stdin', '-s', action='store_true', default=False,
                        help='Take input from stdin')
    rungroup.add_argument('--daemon', '-d', action='store_true', default=False,
                          help='run image display as daemon')
    rungroup.add_argument('--client', '-c', action='store_true', default=False,
                          help='run image display as client')
    parser.add_argument('--pipe', '-p', default=os.getppid(),
                        help='override daemon pipe name')
    parser.add_argument('--width', '-w', default=0, type=int,
                        help='image width')
    parser.add_argument('--height', '-H', default=0, type=int,
                        help='image height')
    parser.add_argument('-x', default=0, type=int,
                        help='image x position')
    parser.add_argument('-y', default=0, type=int,
                        help='image y position')

    return parser.parse_args()


def signal_handler(fifo):
    def sig_handle(signum, frame):
        try:
            os.remove(fifo)
        except FileNotFoundError:
            pass
        sys.exit()

    return sig_handle


def placement_gen(canvas, x, y, h, w):
    p = canvas.create_placement('demo', x=x, y=y, width=w, height=h,
                                scaler=ueberzug.ScalerOption.CONTAIN.value)
    p.path = None
    p.visibility = ueberzug.Visibility.VISIBLE

    return p


def pipe_read(fifo):
    try:
        os.mkfifo(fifo)
    except OSError as oe:
        if oe.errno != errno.EEXIST:
            raise

    try:
        while True:
            with open(fifo) as f:
                while True:
                    data = f.read()
                    if len(data) == 0:
                        break
                    yield data.strip()
    except KeyboardInterrupt:
        return


def daemon_run(placement, fifo):
    for line in pipe_read(fifo):
        placement.path = line.strip()


def client_run(img, fifo):
    with open(fifo, 'w') as f:
        f.write(f'{img}\n')


def run(placement, img):
    placement.path = img
    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        return


@ueberzug.Canvas()
def main(canvas):
    opts = get_opts()

    fifo = f'/tmp/img_{opts.pipe}_pipe'
    placement = placement_gen(canvas, opts.x, opts.y, opts.height, opts.width)

    signal.signal(signal.SIGINT, signal_handler(fifo))
    signal.signal(signal.SIGHUP, signal_handler(fifo))

    if opts.daemon:
        daemon_run(placement, fifo)
    elif opts.client:
        if opts.stdin:
            #  parser.add_argument('--img', '-i', default=sys.stdin.readline().strip(),
            img = sys.stdin.readline().strip()
        else:
            img = opts.img
        client_run(img, fifo)
    else:
        run(placement, opts.img)


if __name__ == '__main__':
    main()
