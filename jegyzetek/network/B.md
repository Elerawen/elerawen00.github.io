Feladat: B  
Kellő CISCO eszközök: 1 switch, 1 router  
  
2  
a  
```
hostname Szokolai  
line console 0  
password BMSzCViszga  
login  
exit  
```
  
b  
```
interface range FastEthernet 0/1 - 9, FastEthernet 0/12 - 24  
switchport mode access  
switchport access vlan 22  
shutdown  
```
  
c  
```
interface FastEthernet 0/11  
switchport mode access  
switchport access vlan 10  
no shutdown  
```
  
d  
```
interface FastEthernet 0/10  
switchport mode trunk  
switchport trunk encapsulation dot1q (ha lehet)  
no shutdown  
```
  
e  
```
interface vlan 10  
ip add 10.VSZ.10.10 255.255.255.128  
no shutdown  
exit  
```
  
f  
```
ip default-gateway 10.VSZ.10.1  
```
  
g  
```
username admin privilege 15 secret BMSzC  
```
  
h  
```
ip domain-name pataky.lan  
```
  
i  
```
crypto key generate rsa  
    1024  
```
  
j  
```
line vty 0 3  
login local  
transport input ssh  
exit
```  
  
k  
```
vlan 10  
name Pataky10  
interface range FastEthernet 0/11 - 13  
switchport mode access  
switchport access vlan 10  
exit  
vlan 20  
name Pataky20  
interface range FastEthernet 0/14 - 16  
switchport mode access  
switchport access vlan 20  
```
  
3  
a  
```
hostname BMSzCRouterVSZ  
```
  
b  
```
line console 0  
password BMSzCVizsga  
login  
exit  
```
  
c  
```
enable secret BMSzCEna  
```
  
d  
```
interface GigabitEthernet 0/1  
ip address 192.168.TSZ.(GSZ+10) 255.255.255.0  
no shutdown  
```
  
e  
```
ipv6 address FE80::1 link-local  
```
  
f  
```
ipv6 address FC00::1/64  
no shutdown  
```
  
g  
```
interface GigabitEthernet 0/0.10  
encapsulation dot1Q 10  
ip address 10.VSZ.10.1 255.255.255.128  
ipv6 address FE80::1 link-local  
ipv6 address FC10::1/64  
no shutdown  
```
  
h  
```
interface GigabitEthernet 0/0.20  
encapsulation dot1Q 20  
ip address 10.VSZ.20.1 255.255.255.128  
ipv6 address FE80::1 link-local  
ipv6 address FC20::1/64  
no shutdown  
```
  
i  
```
interface GigabitEthernet 0/0.10  
ip nat inside  
interface GigabitEthernet 0/0.20  
ip nat inside  
interface GigabitEthernet 0/1  
ip nat outside  
exit  
access-list 1 permit any  
ip nat inside source list 1 interface GigabitEthernet 0/1 overload  
```
  
j  
```
ipv6 unicast-routing  
```