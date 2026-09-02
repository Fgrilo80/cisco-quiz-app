import '../l10n.dart';

/// One CLI lab: a task against the canned IOS device, with a multiple-choice check.
class LabDef {
  const LabDef({
    required this.id,
    required this.titlePt,
    required this.titleEn,
    required this.taskPt,
    required this.taskEn,
    required this.hint,
    required this.optionsPt,
    required this.optionsEn,
    required this.correct,
    required this.explainPt,
    required this.explainEn,
  });

  final String id;
  final String titlePt;
  final String titleEn;
  final String taskPt;
  final String taskEn;
  final String hint;
  final List<String> optionsPt;
  final List<String> optionsEn;
  final int correct;
  final String explainPt;
  final String explainEn;

  String title(S s) => s.isPt ? titlePt : titleEn;
  String task(S s) => s.isPt ? taskPt : taskEn;
  List<String> options(S s) => s.isPt ? optionsPt : optionsEn;
  String explain(S s) => s.isPt ? explainPt : explainEn;

  bool isCorrect(int? answer) => answer != null && answer == correct;
}

const List<LabDef> labCatalog = [
  LabDef(
    id: 'int-down',
    titlePt: 'Interface em baixo',
    titleEn: 'Interface down',
    taskPt:
        'Usa o terminal. Qual interface está down (não administratively down)?',
    taskEn: 'Use the terminal. Which interface is down (not administratively down)?',
    hint: 'show ip interface brief',
    optionsPt: [
      'GigabitEthernet0/0',
      'GigabitEthernet0/2',
      'Vlan1',
      'Loopback0',
    ],
    optionsEn: [
      'GigabitEthernet0/0',
      'GigabitEthernet0/2',
      'Vlan1',
      'Loopback0',
    ],
    correct: 1,
    explainPt: 'Gi0/2 aparece como down/down e unassigned. Vlan1 está administratively down.',
    explainEn:
        'Gi0/2 shows down/down and unassigned. Vlan1 is administratively down.',
  ),
  LabDef(
    id: 'vlan-admin',
    titlePt: 'VLAN encerrada',
    titleEn: 'Shutdown VLAN',
    taskPt: 'Qual SVI está administratively down?',
    taskEn: 'Which SVI is administratively down?',
    hint: 'show ip interface brief',
    optionsPt: ['Vlan10', 'Vlan20', 'Vlan1', 'GigabitEthernet0/2'],
    optionsEn: ['Vlan10', 'Vlan20', 'Vlan1', 'GigabitEthernet0/2'],
    correct: 2,
    explainPt: 'Vlan1 está "administratively down / down". Gi0/2 está só down.',
    explainEn: 'Vlan1 is "administratively down / down". Gi0/2 is just down.',
  ),
  LabDef(
    id: 'vlan-name',
    titlePt: 'Nome da VLAN 10',
    titleEn: 'VLAN 10 name',
    taskPt: 'Qual é o nome da VLAN 10?',
    taskEn: 'What is the name of VLAN 10?',
    hint: 'show vlan brief',
    optionsPt: ['default', 'ENG', 'SALES', 'GUEST'],
    optionsEn: ['default', 'ENG', 'SALES', 'GUEST'],
    correct: 2,
    explainPt: 'VLAN 10 chama-se SALES (portas Gi1/0/9-10).',
    explainEn: 'VLAN 10 is named SALES (ports Gi1/0/9-10).',
  ),
  LabDef(
    id: 'vlan-ports',
    titlePt: 'Portas da VLAN 20',
    titleEn: 'VLAN 20 ports',
    taskPt: 'Que VLAN contém Gi1/0/5 a Gi1/0/8?',
    taskEn: 'Which VLAN contains Gi1/0/5 through Gi1/0/8?',
    hint: 'show vlan brief',
    optionsPt: [
      'VLAN 1 default',
      'VLAN 10 SALES',
      'VLAN 20 ENG',
      'VLAN 99 MGMT',
    ],
    optionsEn: [
      'VLAN 1 default',
      'VLAN 10 SALES',
      'VLAN 20 ENG',
      'VLAN 99 MGMT',
    ],
    correct: 2,
    explainPt: 'VLAN 20 (ENG) tem Gi1/0/5, Gi1/0/6, Gi1/0/7 e Gi1/0/8.',
    explainEn: 'VLAN 20 (ENG) has Gi1/0/5, Gi1/0/6, Gi1/0/7 and Gi1/0/8.',
  ),
  LabDef(
    id: 'gateway',
    titlePt: 'Gateway of last resort',
    titleEn: 'Gateway of last resort',
    taskPt: 'Qual é o gateway of last resort?',
    taskEn: 'What is the gateway of last resort?',
    hint: 'show ip route',
    optionsPt: ['10.0.0.2', '192.168.1.1', '192.168.1.254', '1.1.1.1'],
    optionsEn: ['10.0.0.2', '192.168.1.1', '192.168.1.254', '1.1.1.1'],
    correct: 2,
    explainPt: 'A tabela mostra "Gateway of last resort is 192.168.1.254" (rota estática S*).',
    explainEn: 'The table shows "Gateway of last resort is 192.168.1.254" (static S*).',
  ),
  LabDef(
    id: 'etherchannel-proto',
    titlePt: 'Protocolo EtherChannel',
    titleEn: 'EtherChannel protocol',
    taskPt: 'Que protocolo agrega o Port-channel 1?',
    taskEn: 'Which protocol aggregates Port-channel 1?',
    hint: 'show etherchannel summary',
    optionsPt: ['PAgP', 'LACP', 'Static (on)', 'NONE'],
    optionsEn: ['PAgP', 'LACP', 'Static (on)', 'NONE'],
    correct: 1,
    explainPt: 'Po1(SU) usa LACP, com Gi1/0/1(P) e Gi1/0/2(P).',
    explainEn: 'Po1(SU) uses LACP, with Gi1/0/1(P) and Gi1/0/2(P).',
  ),
  LabDef(
    id: 'etherchannel-ports',
    titlePt: 'Membros do Po1',
    titleEn: 'Po1 members',
    taskPt: 'Quais portas estão bundled no Po1?',
    taskEn: 'Which ports are bundled in Po1?',
    hint: 'show etherchannel summary',
    optionsPt: [
      'Gi0/1 e Gi0/2',
      'Gi1/0/1 e Gi1/0/2',
      'Gi1/0/5 e Gi1/0/6',
      'Gi1/0/9 e Gi1/0/10',
    ],
    optionsEn: [
      'Gi0/1 and Gi0/2',
      'Gi1/0/1 and Gi1/0/2',
      'Gi1/0/5 and Gi1/0/6',
      'Gi1/0/9 and Gi1/0/10',
    ],
    correct: 1,
    explainPt: 'O resumo lista Gi1/0/1(P) e Gi1/0/2(P) no grupo 1.',
    explainEn: 'The summary lists Gi1/0/1(P) and Gi1/0/2(P) in group 1.',
  ),
  LabDef(
    id: 'cdp-nei',
    titlePt: 'Vizinho CDP',
    titleEn: 'CDP neighbor',
    taskPt: 'Que dispositivo está ligado a Gig 0/1?',
    taskEn: 'Which device is connected to Gig 0/1?',
    hint: 'show cdp neighbors',
    optionsPt: ['SW2.lab.local', 'AP1.lab.local', 'R1.lab.local', 'ISR4331'],
    optionsEn: ['SW2.lab.local', 'AP1.lab.local', 'R1.lab.local', 'ISR4331'],
    correct: 2,
    explainPt:
        'R1.lab.local aparece em Local Intrfce Gig 0/1 (plataforma ISR4331).',
    explainEn: 'R1.lab.local is on Local Intrfce Gig 0/1 (platform ISR4331).',
  ),
  LabDef(
    id: 'ospf-dr',
    titlePt: 'OSPF Designated Router',
    titleEn: 'OSPF Designated Router',
    taskPt: 'Qual é o Router ID do vizinho em estado FULL/DR?',
    taskEn: 'What is the Router ID of the neighbor in FULL/DR?',
    hint: 'show ip ospf neighbor',
    optionsPt: ['1.1.1.1', '2.2.2.2', '3.3.3.3', '10.0.0.2'],
    optionsEn: ['1.1.1.1', '2.2.2.2', '3.3.3.3', '10.0.0.2'],
    correct: 1,
    explainPt: '2.2.2.2 está FULL/DR em GigabitEthernet0/1; 3.3.3.3 é BDR.',
    explainEn: '2.2.2.2 is FULL/DR on GigabitEthernet0/1; 3.3.3.3 is BDR.',
  ),
  LabDef(
    id: 'bgp-idle',
    titlePt: 'Sessão BGP Idle',
    titleEn: 'Idle BGP session',
    taskPt: 'Que vizinho BGP está Idle?',
    taskEn: 'Which BGP neighbor is Idle?',
    hint: 'show ip bgp summary',
    optionsPt: ['10.0.0.2', '203.0.113.1', '192.0.2.8', '1.1.1.1'],
    optionsEn: ['10.0.0.2', '203.0.113.1', '192.0.2.8', '1.1.1.1'],
    correct: 2,
    explainPt: '192.0.2.8 (AS 65002) está Idle, Up/Down never, 0 prefixes.',
    explainEn: '192.0.2.8 (AS 65002) is Idle, Up/Down never, 0 prefixes.',
  ),
  LabDef(
    id: 'run-desc',
    titlePt: 'Descrição Gi0/0',
    titleEn: 'Gi0/0 description',
    taskPt: 'Qual é a description de GigabitEthernet0/0? (podes precisar de enable)',
    taskEn:
        'What is the description of GigabitEthernet0/0? (you may need enable)',
    hint: 'enable  →  show running-config',
    optionsPt: ['TO-R2', 'UNUSED', 'UPLINK-WAN', 'SALES'],
    optionsEn: ['TO-R2', 'UNUSED', 'UPLINK-WAN', 'SALES'],
    correct: 2,
    explainPt: 'show running-config (modo privilegiado) mostra "description UPLINK-WAN" em Gi0/0.',
    explainEn: 'show running-config (privileged EXEC) shows "description UPLINK-WAN" on Gi0/0.',
  ),
  LabDef(
    id: 'run-ospf',
    titlePt: 'Processo OSPF',
    titleEn: 'OSPF process',
    taskPt: 'Qual é o process ID OSPF no running-config?',
    taskEn: 'What is the OSPF process ID in the running-config?',
    hint: 'enable  →  show running-config',
    optionsPt: ['1', '10', '110', '65001'],
    optionsEn: ['1', '10', '110', '65001'],
    correct: 0,
    explainPt: 'A config tem "router ospf 1" com router-id 1.1.1.1.',
    explainEn: 'The config has "router ospf 1" with router-id 1.1.1.1.',
  ),
];
