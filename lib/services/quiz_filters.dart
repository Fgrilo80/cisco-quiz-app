import '../models/question.dart';
import '../models/quiz_session.dart';

const kDifficultyEasy = 'easy';
const kDifficultyMedium = 'medium';
const kDifficultyHard = 'hard';
const kOtherTopic = 'other';

class TopicDef {
  const TopicDef(this.id, this.labelPt, this.labelEn, this.terms);

  final String id;
  final String labelPt;
  final String labelEn;
  final List<String> terms;
}

const kTopicCatalog = <TopicDef>[
  TopicDef('vlan', 'VLAN', 'VLAN', ['vlan', 'vlans', '802.1q']),
  TopicDef('ospf', 'OSPF', 'OSPF', ['ospf']),
  TopicDef('eigrp', 'EIGRP', 'EIGRP', ['eigrp']),
  TopicDef('bgp', 'BGP', 'BGP', ['ebgp', 'ibgp', 'bgp']),
  TopicDef('stp', 'STP', 'STP', [
    'rstp',
    'mstp',
    'pvst',
    'spanning-tree',
    'spanning tree',
    'stp',
  ]),
  TopicDef('acl', 'ACL', 'ACL', ['access-list', 'access list', 'acls', 'acl']),
  TopicDef('nat', 'NAT', 'NAT', [
    'port address translation',
    'network address translation',
    'nat',
    'pat',
  ]),
  TopicDef('qos', 'QoS', 'QoS', [
    'quality of service',
    'diffserv',
    'dscp',
    'qos',
  ]),
  TopicDef('wifi', 'Wi-Fi', 'Wi-Fi', [
    'wi-fi',
    'wifi',
    'wlan',
    'ssid',
    'wpa2',
    'wpa3',
    'capwap',
    '802.11',
    'wireless',
    'wlc',
    'wpa',
  ]),
  TopicDef('ipv6', 'IPv6', 'IPv6', ['ipv6', 'slaac', 'eui-64', 'eui64']),
  TopicDef('dhcp', 'DHCP', 'DHCP', ['dhcp']),
  TopicDef('vpn', 'VPN', 'VPN', ['anyconnect', 'ipsec', 'vpn', 'ike']),
  TopicDef('hsrp', 'HSRP', 'HSRP', ['hsrp', 'vrrp', 'glbp', 'fhrp']),
  TopicDef('etherchannel', 'EtherChannel', 'EtherChannel', [
    'etherchannel',
    'port-channel',
    'portchannel',
    'lacp',
    'pagp',
  ]),
  TopicDef('subnetting', 'Sub-redes', 'Subnetting', [
    'sub-rede',
    'subrede',
    'subnet',
    'wildcard',
    'cidr',
  ]),
  TopicDef('aaa', 'AAA', 'AAA', ['tacacs', 'radius', '802.1x', 'aaa']),
  TopicDef('snmp', 'SNMP', 'SNMP', ['netflow', 'syslog', 'snmp']),
  TopicDef('automation', 'Automatização', 'Automation', [
    'restconf',
    'netconf',
    'ansible',
    'yang',
  ]),
  TopicDef('mpls', 'MPLS', 'MPLS', ['mpls']),
  TopicDef('sdwan', 'SD-WAN', 'SD-WAN', ['sd-wan', 'sdwan']),
  TopicDef('tcpip', 'TCP/IP', 'TCP/IP', [
    'tcp/ip',
    'transport layer',
    'camada de transporte',
    'osi model',
    'modelo osi',
  ]),
  TopicDef('ethernet', 'Ethernet', 'Ethernet', [
    'ethernet',
    'crossover',
    'poe',
    'colisão',
    'collision',
  ]),
  TopicDef('arp', 'ARP', 'ARP', ['arp']),
  TopicDef('routing', 'Routing', 'Routing', [
    'default gateway',
    'gateway padrão',
    'gateway padrao',
    'routing table',
    'tabela de encaminhamento',
    'static route',
    'rota estática',
    'rota estatica',
    'ip route',
  ]),
];

final Map<String, TopicDef> _topicsById = {
  for (final t in kTopicCatalog) t.id: t,
};

String _fold(String raw) {
  final lower = raw.toLowerCase();
  return lower
      .replaceAll('á', 'a')
      .replaceAll('à', 'a')
      .replaceAll('ã', 'a')
      .replaceAll('â', 'a')
      .replaceAll('é', 'e')
      .replaceAll('ê', 'e')
      .replaceAll('í', 'i')
      .replaceAll('ó', 'o')
      .replaceAll('ô', 'o')
      .replaceAll('õ', 'o')
      .replaceAll('ú', 'u')
      .replaceAll('ç', 'c');
}

String canonicalDifficulty(String raw) {
  final s = _fold(raw.trim());
  if (s.isEmpty) return '';
  if (s == 'easy' || s.startsWith('facil')) return kDifficultyEasy;
  if (s == 'hard' || s == 'difficult' || s.startsWith('dificil')) {
    return kDifficultyHard;
  }
  if (s == 'medium' || s.startsWith('medio')) return kDifficultyMedium;
  return '';
}

String? canonicalTopicId(String raw) {
  final folded = _fold(raw.trim());
  if (folded.isEmpty) return null;
  if (folded == kOtherTopic || folded == 'outros' || folded == 'other') {
    return kOtherTopic;
  }
  for (final t in kTopicCatalog) {
    if (folded == t.id) return t.id;
    if (folded == _fold(t.labelPt) || folded == _fold(t.labelEn)) return t.id;
  }
  return null;
}

String slugTopic(String raw) {
  final folded = _fold(raw.trim());
  final slug = folded.replaceAll(RegExp(r'[^a-z0-9]+'), '-');
  final trimmed = slug.replaceAll(RegExp(r'^-+|-+$'), '');
  return trimmed.isEmpty ? kOtherTopic : trimmed;
}

bool _hasTerm(String haystack, String term) {
  final t = _fold(term);
  if (t.contains(' ') || t.contains('-') || t.contains('/')) {
    return haystack.contains(t);
  }
  return RegExp('\\b${RegExp.escape(t)}\\b').hasMatch(haystack);
}

String deriveTopic(String haystack) {
  final hay = _fold(haystack);
  if (hay.trim().isEmpty) return kOtherTopic;
  for (final topic in kTopicCatalog) {
    for (final term in topic.terms) {
      if (_hasTerm(hay, term)) return topic.id;
    }
  }
  return kOtherTopic;
}

String resolveTopic({String? jsonTopic, required String haystack}) {
  final explicit = jsonTopic?.trim() ?? '';
  if (explicit.isNotEmpty) {
    return canonicalTopicId(explicit) ?? slugTopic(explicit);
  }
  return deriveTopic(haystack);
}

String topicLabel(String id, {required bool isPt}) {
  if (id == kOtherTopic) return isPt ? 'Outros' : 'Other';
  final def = _topicsById[id];
  if (def == null) return id;
  return isPt ? def.labelPt : def.labelEn;
}

List<String> orderedTopicIds(Iterable<String> present) {
  final set = present.toSet();
  final out = <String>[
    for (final t in kTopicCatalog)
      if (set.contains(t.id)) t.id,
  ];
  if (set.contains(kOtherTopic)) out.add(kOtherTopic);
  final known = out.toSet();
  final extra = set.where((id) => !known.contains(id)).toList()..sort();
  out.addAll(extra);
  return out;
}

String haystackOf(Question q) {
  final buf = StringBuffer()
    ..write(q.question)
    ..write(' ')
    ..write(q.explanation)
    ..write(' ')
    ..write(q.options.join(' '));
  if (q.hasCli) {
    buf.write(' ');
    buf.write(q.cli);
  }
  return buf.toString();
}

String difficultyOf(Question q) => canonicalDifficulty(q.difficulty);

String topicOf(Question q) =>
    resolveTopic(jsonTopic: q.topic, haystack: haystackOf(q));

List<String> topicsPresentIn(Iterable<Question> pool) =>
    orderedTopicIds(pool.map(topicOf));

List<Question> applyFilters(
  List<Question> pool, {
  String? difficulty,
  String? topic,
}) {
  final wantDiff = (difficulty == null || difficulty.isEmpty)
      ? null
      : difficulty;
  final wantTopic = (topic == null || topic.isEmpty) ? null : topic;
  if (wantDiff == null && wantTopic == null) return pool;
  return [
    for (final q in pool)
      if ((wantDiff == null || difficultyOf(q) == wantDiff) &&
          (wantTopic == null || topicOf(q) == wantTopic))
        q,
  ];
}

int remainingCount(List<Question> pool, {String? difficulty, String? topic}) =>
    applyFilters(pool, difficulty: difficulty, topic: topic).length;

int filteredExamCount(int available, {int cap = quizLength}) {
  if (available <= 0) return 0;
  return available < cap ? available : cap;
}

int sessionSecondsFor(int questionCount) {
  if (questionCount <= 0) return quizSeconds;
  if (questionCount >= quizLength) return quizSeconds;
  final scaled = (quizSeconds * questionCount / quizLength).round();
  return scaled.clamp(3 * 60, quizSeconds);
}
