import 'package:cisco_quiz/labs/ios_cli.dart';
import 'package:cisco_quiz/labs/lab_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'show ip interface brief lists Gi0/2 down and is distinct from vlan',
    () {
      final cli = IosCli();
      final out = cli.exec('show ip interface brief');
      expect(out, contains('GigabitEthernet0/2'));
      expect(out, contains('unassigned'));
      expect(out, contains('down'));
      expect(out, isNot(contains('SALES')));
      expect(out, isNot(IosCli.showVlanBrief));
    },
  );

  test(
    'show vlan brief lists VLAN 20 ENG and is distinct from ip int brief',
    () {
      final cli = IosCli();
      final out = cli.exec('show vlan brief');
      expect(out, contains('ENG'));
      expect(out, contains('Gi1/0/5'));
      expect(out, isNot(contains('192.168.1.1')));
      expect(out, isNot(IosCli.showIpInterfaceBrief));
    },
  );

  test('abbreviations and remaining show commands have distinct output', () {
    final cli = IosCli()..exec('enable');
    expect(cli.exec('sh ip int br'), contains('GigabitEthernet0/0'));
    expect(cli.exec('show ip route'), contains('192.168.1.254'));
    expect(cli.exec('show etherchannel summary'), contains('LACP'));
    expect(cli.exec('show cdp neighbors'), contains('R1.lab.local'));
    expect(cli.exec('show ip ospf neighbor'), contains('FULL/DR'));
    expect(cli.exec('show ip bgp summary'), contains('Idle'));
    expect(cli.exec('show running-config'), contains('UPLINK-WAN'));
  });

  test('new show commands return lab-checkable output', () {
    final cli = IosCli();
    expect(cli.exec('show ip route ospf'), contains('O IA'));
    expect(cli.exec('show ip route ospf'), contains('10.3.3.0/24'));
    expect(cli.exec('show spanning-tree vlan 10'), contains('0011.2233.4455'));
    expect(cli.exec('sh span vlan 10'), contains('Root ID'));
    expect(cli.exec('show interfaces status'), contains('notconnect'));
    expect(cli.exec('show interfaces status'), contains('Gi1/0/7'));
    expect(cli.exec('show ip dhcp binding'), contains('10.20.20.88'));
    expect(cli.exec('show ip nat translations'), contains('203.0.113.11'));
    expect(cli.exec('show access-lists'), contains('10.30.30.0'));
    expect(cli.exec('show access-list'), contains('BLOCK-GUEST'));
    expect(cli.exec('show logging'), contains('Trap logging: level warnings'));
  });

  test('show run | include filters lines', () {
    final cli = IosCli()..exec('enable');
    final out = cli.exec('show run | include hostname');
    expect(out, contains('hostname SW1'));
    expect(out, isNot(contains('interface')));
  });

  test('config hostname and interface persist in show run', () {
    final cli = IosCli()..exec('enable');
    cli.exec('configure terminal');
    expect(cli.prompt, 'SW1(config)#');
    cli.exec('hostname LAB-CORE');
    expect(cli.prompt, 'LAB-CORE(config)#');
    cli.exec('interface Gi0/2');
    expect(cli.prompt, 'LAB-CORE(config-if)#');
    cli.exec('ip address 172.16.0.1 255.255.255.0');
    cli.exec('no shutdown');
    cli.exec('end');
    expect(cli.prompt, 'LAB-CORE#');
    final run = cli.exec('show running-config');
    expect(run, contains('hostname LAB-CORE'));
    expect(run, contains('172.16.0.1'));
    expect(cli.exec('show run | include 172.16.0.1'), contains('172.16.0.1'));
  });

  test('config ospf network statement appears in show run', () {
    final cli = IosCli()..exec('enable');
    cli.exec('conf t');
    cli.exec('router ospf 1');
    expect(cli.prompt, contains('(config-router)#'));
    cli.exec('network 10.20.20.0 0.0.0.255 area 0');
    cli.exec('end');
    final filtered = cli.exec('show run | include 10.20.20');
    expect(filtered, contains('network 10.20.20.0 0.0.0.255 area 0'));
  });

  test('enable, exit and ? change privilege and print help', () {
    final cli = IosCli();
    expect(cli.prompt, 'SW1>');
    expect(cli.exec('?'), contains('enable'));
    cli.exec('enable');
    expect(cli.prompt, 'SW1#');
    expect(cli.exec('?'), contains('configure'));
    cli.exec('exit');
    expect(cli.prompt, 'SW1>');
    expect(cli.exec('show running-config'), IosCli.notAuth);
  });

  test('lab catalog has unique labs with valid checks', () {
    expect(labCatalog.length, greaterThanOrEqualTo(20));
    expect(labCatalog.map((l) => l.id).toSet().length, labCatalog.length);
    for (final lab in labCatalog) {
      expect(lab.optionsPt.length, greaterThanOrEqualTo(2));
      expect(lab.optionsPt.length, lab.optionsEn.length);
      expect(lab.correct, inInclusiveRange(0, lab.optionsPt.length - 1));
      expect(lab.isCorrect(lab.correct), isTrue);
      expect(lab.isCorrect(lab.correct == 0 ? 1 : 0), isFalse);
      expect(lab.titlePt, isNotEmpty);
      expect(lab.titleEn, isNotEmpty);
      expect(lab.hint, isNotEmpty);
    }
  });
}
