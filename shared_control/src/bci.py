#!/usr/bin/env python
#-*-coding: utf-8-*-

import rospy
import termios
import sys
import select
import tty
import socket

from geometry_msgs.msg import Pose
from std_msgs.msg import Int32
from visualization_msgs.msg import MarkerArray, Marker

from shared_control.srv import MotorImagery, Node


class FAKE_BCI:
    """BCI를 키보드로 대체한다"""
    def __init__(self):
        self.key = ''
        self.key_setting = termios.tcgetattr(sys.stdin)
        self.key_watcher = rospy.Timer(rospy.Duration(0.1), self.spin)
        self.pose = Pose()

        rospy.Subscriber('robot/pose', Pose, self.update_pose)

        self.eyeblink_publisher = rospy.Publisher('bci/eyeblink', Int32, queue_size=1)

        rospy.Service('bci/motorimagery', MotorImagery, self.motorimagery)

        rospy.wait_for_service('gvg/node')
        self.get_node = rospy.ServiceProxy('gvg/node', Node)

        self.connect()

    def connect(self):
        # Create Server
        ADRESS_IP = rospy.get_param('~address_ip') # IP of this computer(localhost로는 안됨)
        print(socket.gethostbyname(socket.getfqdn()))
        # ADRESS_IP = raw_input("IP ADRESS")
        ADRESS_PORT = rospy.get_param('~address_port')

        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        s.bind((ADRESS_IP,ADRESS_PORT))
        s.listen(10)

        conn, addr = s.accept()
        self.conn = conn
        self.conn.settimeout(None)
        print 'Connected with ' + addr[0] + ':' + str(addr[1])
        # Connect Server

    def __del__(self):
        termios.tcsetattr(sys.stdin, termios.TCSADRAIN, self.key_setting)

    def spin(self, event):
        # """키보드 입력을 획득한다"""
        # tty.setraw(sys.stdin.fileno())  # 키보드와 연결한다.

        # rlist, _, _ = select.select([sys.stdin], [], [], 0.1)
        # if rlist:
        #     self.key = sys.stdin.read(1)
        #     if self.key == '\x03':      # ctrl+c가 들어오면 키보드와의 연결을 종료한다.
        #         self.key_watcher.shutdown()
        #     elif self.key == 'w':       # Eye blink를 대신하여 trigger를 발행한다.
        #         self.eyeblink_publisher.publish(2)
        # else:
        #     self.key = ''

        # termios.tcsetattr(sys.stdin, termios.TCSADRAIN, self.key_setting)

        """신호 받아온다"""
        try:
            sig = self.conn.recv(1024)
            self.key = sig
        except:
            self.key = ''

        if self.key == '\x03':      # ctrl+c가 들어오면 키보드와의 연결을 종료한다.
            self.key_watcher.shutdown()
            self.key = ''
        elif self.key == 'w':       # Eye blink를 대신하여 trigger를 발행한다.
            self.eyeblink_publisher.publish(2)
            self.key = ''

        termios.tcsetattr(sys.stdin, termios.TCSADRAIN, self.key_setting)

    def motorimagery(self, request):
        # """Motor imagery를 대신하여 binary question에 답변한다"""
        # rospy.loginfo('이동할까요? 긍정은 a, 부정은 d: ')

        # answer = -1
        # key = 'fini'
        # while (key != 'a')&(key != 'd'):    # 답변이 들어올 때까지 키를 확인한다.
        #     key = self.key
        #     if self.key == 'a':             # a가 들어오면 첫번째 값을 돌려준다.
        #         answer = request.ids[0]
        #     elif self.key == 'd':           # d가 들어오면 두번째 값을 돌려준다.
        #         answer = request.ids[1]

        #     rospy.sleep(0.1)

        # return {'id': answer}

        """Motor imagery를 대신하여 binary question에 답변한다"""
        rospy.loginfo('이동할까요? 신호 입력 대기중')

        answer = -1
        key = 'fini'
        while (key != 'a')&(key != 'd'):    # 답변이 들어올 때까지 키를 확인한다.
            key = self.key
            print(key)
            if self.key == 'a':             # a가 들어오면 첫번째 값을 돌려준다.
                answer = request.ids[0]
            elif self.key == 'd':           # d가 들어오면 두번째 값을 돌려준다.
                answer = request.ids[1]
            self.key = ''
            rospy.sleep(0.1)

        return {'id': answer}


    def update_pose(self, data):
        """로봇의 자세를 갱신한다"""
        self.pose = data


if __name__ == '__main__':
    rospy.init_node('fake_bci')
    fake_bci = FAKE_BCI()
    rospy.spin()