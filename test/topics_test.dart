import 'package:cisco_quiz/models/question.dart';
import 'package:cisco_quiz/services/quiz_filters.dart';
import 'package:flutter_test/flutter_test.dart';

Question q({
  required String text,
  String explanation = '',
  String difficulty = 'Fácil',
  String? topic,
  List<String> options = const ['a', 'b', 'c', 'd'],
}) => Question(
  question: text,
  options: options,
  correct: 1,
  explanation: explanation,
  difficulty: difficulty,
  topic: topic,
);

void main() {
  test('derives VLAN from keywords and not NAT from native', () {
    final item = q(text: 'Qual é a native VLAN no trunk?');
    expect(topicOf(item), 'vlan');
    expect(topicOf(item), isNot('nat'));
  });

  test('derives listed Cisco topics from keywords', () {
    expect(topicOf(q(text: 'OSPF DR/BDR election')), 'ospf');
    expect(topicOf(q(text: 'Configure Wi-Fi SSID on the WLC')), 'wifi');
    expect(topicOf(q(text: 'Named ACL and access-list 100')), 'acl');
    expect(topicOf(q(text: 'Inside global NAT overload')), 'nat');
    expect(topicOf(q(text: 'RSTP BPDU guard')), 'stp');
    expect(topicOf(q(text: 'eBGP neighbor in AS 65000')), 'bgp');
    expect(topicOf(q(text: 'Mark DSCP AF41 for QoS')), 'qos');
  });

  test('uses JSON topic when present instead of inventing one', () {
    final item = q(text: 'Something generic about routers', topic: 'OSPF');
    expect(topicOf(item), 'ospf');
  });

  test('unmatched questions go to other, not a made-up Cisco item', () {
    final item = q(text: 'How many bits in a MAC address?');
    expect(topicOf(item), kOtherTopic);
    expect(topicLabel(kOtherTopic, isPt: true), 'Outros');
    expect(topicLabel(kOtherTopic, isPt: false), 'Other');
  });

  test('topicsPresentIn only lists topics that exist in the pool', () {
    final pool = [
      q(text: 'VLAN 10'),
      q(text: 'OSPF area 0'),
      q(text: 'How many bits in a MAC address?'),
    ];
    expect(topicsPresentIn(pool), ['vlan', 'ospf', kOtherTopic]);
  });
}
