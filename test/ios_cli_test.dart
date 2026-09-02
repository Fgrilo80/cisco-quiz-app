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

  test('lab catalog has 8 to 12 labs with a check', () {
    expect(labCatalog.length, inInclusiveRange(8, 12));
    expect(labCatalog.map((l) => l.id).toSet().length, labCatalog.length);
    for (final lab in labCatalog) {
      expect(lab.optionsPt.length, greaterThanOrEqualTo(2));
      expect(lab.optionsPt.length, lab.optionsEn.length);
      expect(lab.correct, inInclusiveRange(0, lab.optionsPt.length - 1));
      expect(lab.isCorrect(lab.correct), isTrue);
      expect(lab.isCorrect(lab.correct == 0 ? 1 : 0), isFalse);
    }
  });
}
