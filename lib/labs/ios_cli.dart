/// Canned Cisco IOS-like CLI for Labs. Not a real device — deterministic output.
enum IosPrivilege { user, privileged, config, configIf, configRouter }

class IosCli {
  IosCli({this.hostname = 'SW1'});

  String hostname;
  IosPrivilege privilege = IosPrivilege.user;

  /// Interface currently being configured (e.g. GigabitEthernet0/2).
  String? _configIf;

  /// OSPF process in router submode.
  int? _ospfProcess;

  /// Runtime overrides applied by config mode (merged into show run).
  final Map<String, _IfState> _ifOverrides = {};
  final List<String> _extraOspfNetworks = [];

  String get prompt {
    switch (privilege) {
      case IosPrivilege.user:
        return '$hostname>';
      case IosPrivilege.privileged:
        return '$hostname#';
      case IosPrivilege.config:
        return '$hostname(config)#';
      case IosPrivilege.configIf:
        return '$hostname(config-if)#';
      case IosPrivilege.configRouter:
        return '$hostname(config-router)#';
    }
  }

  static const invalid = "% Invalid input detected at '^' marker.";
  static const incomplete = '% Incomplete command.';
  static const ambiguous = '% Ambiguous command.';
  static const notAuth =
      '% Authorization failed. Privileged EXEC required (enable).';

  static const showIpInterfaceBrief = """
Interface              IP-Address      OK? Method Status                Protocol
GigabitEthernet0/0     192.168.1.1     YES manual up                    up
GigabitEthernet0/1     10.0.0.1        YES manual up                    up
GigabitEthernet0/2     unassigned      YES unset  down                  down
GigabitEthernet0/3     172.16.10.1     YES manual up                    up
Vlan1                  192.168.99.1    YES manual administratively down down
Vlan10                 10.10.10.1      YES manual up                    up
Vlan20                 10.20.20.1      YES manual up                    up
Loopback0              1.1.1.1         YES manual up                    up""";

  static const showVlanBrief = """
VLAN Name                             Status    Ports
---- -------------------------------- --------- -------------------------------
1    default                          active    Gi1/0/1, Gi1/0/2, Gi1/0/3, Gi1/0/4
10   SALES                            active    Gi1/0/9, Gi1/0/10
20   ENG                              active    Gi1/0/5, Gi1/0/6, Gi1/0/7, Gi1/0/8
30   GUEST                            active    Gi1/0/11
99   MGMT                             active    Gi1/0/12
1002 fddi-default                     act/unsup
1003 token-ring-default               act/unsup
1004 fddinet-default                  act/unsup
1005 trnet-default                    act/unsup""";

  static const showIpRoute = """
Codes: L - local, C - connected, S - static, R - RIP, M - mobile, B - BGP
       D - EIGRP, EX - EIGRP external, O - OSPF, IA - OSPF inter area
       E1 - OSPF external type 1, E2 - OSPF external type 2
       * - candidate default

Gateway of last resort is 192.168.1.254 to network 0.0.0.0

S*    0.0.0.0/0 [1/0] via 192.168.1.254
      1.0.0.0/32 is subnetted, 1 subnets
C        1.1.1.1 is directly connected, Loopback0
      10.0.0.0/8 is variably subnetted, 4 subnets, 2 masks
C        10.0.0.0/30 is directly connected, GigabitEthernet0/1
L        10.0.0.1/32 is directly connected, GigabitEthernet0/1
O        10.2.2.0/24 [110/2] via 10.0.0.2, 00:12:44, GigabitEthernet0/1
O IA     10.3.3.0/24 [110/12] via 10.0.0.2, 00:12:44, GigabitEthernet0/1
      192.168.1.0/24 is variably subnetted, 2 subnets, 2 masks
C        192.168.1.0/24 is directly connected, GigabitEthernet0/0
L        192.168.1.1/32 is directly connected, GigabitEthernet0/0""";

  static const showIpRouteOspf = """
Codes: L - local, C - connected, S - static, R - RIP, M - mobile, B - BGP
       D - EIGRP, EX - EIGRP external, O - OSPF, IA - OSPF inter area
       E1 - OSPF external type 1, E2 - OSPF external type 2

      10.0.0.0/8 is variably subnetted, 2 subnets, 1 masks
O        10.2.2.0/24 [110/2] via 10.0.0.2, 00:12:44, GigabitEthernet0/1
O IA     10.3.3.0/24 [110/12] via 10.0.0.2, 00:12:44, GigabitEthernet0/1""";

  static const showEtherchannelSummary = """
Flags:  D - down        P - bundled in port-channel
        I - stand-alone s - suspended
        H - Hot-standby (LACP only)
        R - Layer3      S - Layer2
        U - in use      f - failed to allocate aggregator

Number of channel-groups in use: 1
Number of aggregators:           1

Group  Port-channel  Protocol    Ports
------+-------------+-----------+-----------------------------------------------
1      Po1(SU)         LACP      Gi1/0/1(P)   Gi1/0/2(P)""";

  static const showCdpNeighbors = """
Capability Codes: R - Router, T - Trans Bridge, B - Source Route Bridge
                  S - Switch, H - Host, I - IGMP, r - Repeater, P - Phone

Device ID        Local Intrfce     Holdtme    Capability  Platform  Port ID
R1.lab.local     Gig 0/1           148              R S I  ISR4331   Gig 0/0
SW2.lab.local    Gig 0/2           160               S I   WS-C3650  Gig 1/0/1
AP1.lab.local    Gig 1/0/12        120               T     AIR-AP    Gig 0""";

  static const showIpOspfNeighbor = """
Neighbor ID     Pri   State           Dead Time   Address         Interface
2.2.2.2           1   FULL/DR         00:00:38    10.0.0.2        GigabitEthernet0/1
3.3.3.3           1   FULL/BDR        00:00:35    10.0.0.6        GigabitEthernet0/3""";

  static const showIpBgpSummary = """
BGP router identifier 1.1.1.1, local AS number 65001
BGP table version is 12, main routing table version 12
4 network entries using 576 bytes of memory
4 path entries using 320 bytes of memory

Neighbor        V           AS MsgRcvd MsgSent   TblVer  InQ OutQ Up/Down  State/PfxRcd
10.0.0.2        4        65001    1204    1198       12    0    0 08:14:22        2
203.0.113.1     4        65000     890     902       12    0    0 05:02:11        12
192.0.2.8       4        65002       0       0        1    0    0 never          Idle""";

  static const showSpanningTreeVlan10 = """
VLAN0010
  Spanning tree enabled protocol rstp
  Root ID    Priority    24586
             Address     0011.2233.4455
             Cost        4
             Port        9 (GigabitEthernet1/0/9)
             Hello Time   2 sec  Max Age 20 sec  Forward Delay 15 sec

  Bridge ID  Priority    32778  (priority 32768 sys-id-ext 10)
             Address     aabb.cc00.0100
             Hello Time   2 sec  Max Age 20 sec  Forward Delay 15 sec
             Aging Time  300 sec

Interface           Role Sts Cost      Prio.Nbr Type
------------------- ---- --- --------- -------- --------------------------------
Gi1/0/9             Root FWD 4         128.9    P2p
Gi1/0/10            Desg FWD 4         128.10   P2p""";

  static const showInterfacesStatus = """
Port      Name               Status       Vlan       Duplex  Speed Type
Gi1/0/1                      connected    trunk      a-full a-1000 10/100/1000BaseTX
Gi1/0/2                      connected    trunk      a-full a-1000 10/100/1000BaseTX
Gi1/0/3                      connected    1          a-full a-1000 10/100/1000BaseTX
Gi1/0/4                      connected    1          a-full  a-100 10/100/1000BaseTX
Gi1/0/5                      connected    20         a-full a-1000 10/100/1000BaseTX
Gi1/0/6                      connected    20         a-full a-1000 10/100/1000BaseTX
Gi1/0/7                      notconnect   20           auto   auto 10/100/1000BaseTX
Gi1/0/8                      connected    20         a-full a-1000 10/100/1000BaseTX
Gi1/0/9                      connected    10         a-full a-1000 10/100/1000BaseTX
Gi1/0/10                     connected    10         a-full a-1000 10/100/1000BaseTX
Gi1/0/11                     connected    30         a-full  a-100 10/100/1000BaseTX
Gi1/0/12                     connected    99         a-full a-1000 10/100/1000BaseTX
Po1                          connected    trunk      a-full a-1000""";

  static const showIpDhcpBinding = """
Bindings from all pools not associated with VRF:
IP address          Client-ID/              Lease expiration        Type
                    Hardware address/
                    User name
192.168.1.50        0063.6973.636f.2d30.    Mar 15 2026 10:22 AM    Automatic
                    3030.312e.6162.6364.
10.10.10.25         0063.6973.636f.2d61.    Mar 15 2026 11:05 AM    Automatic
                    6263.642e.6566.3031.
10.20.20.88         0050.56c0.0001          Infinite                Manual""";

  static const showIpNatTranslations = """
Pro Inside global      Inside local       Outside local      Outside global
tcp 203.0.113.10:1024  10.10.10.25:443    198.51.100.8:443   198.51.100.8:443
udp 203.0.113.10:53000 10.10.10.25:53000  8.8.8.8:53         8.8.8.8:53
--- 203.0.113.11       10.20.20.88        ---                ---
Total number of translations: 3""";

  static const showAccessLists = """
Extended IP access list 100
    10 permit tcp any any eq www
    20 permit tcp any any eq 443
    30 deny ip 10.30.30.0 0.0.0.255 any
    40 permit ip any any
Extended IP access list BLOCK-GUEST
    10 deny ip 10.30.30.0 0.0.0.255 10.10.10.0 0.0.0.255
    20 permit ip any any
Standard IP access list 10
    10 permit 192.168.1.0, wildcard bits 0.0.0.255""";

  static const showLogging = """
Syslog logging: enabled (0 messages dropped, 0 flushes, 0 overruns)
    Console logging: level debugging, 142 messages logged
    Monitor logging: level debugging, 0 messages logged
    Buffer logging: level informational, 88 messages logged
    Trap logging: level warnings, facility local7
        Logging to 192.168.1.100, 24 message lines logged
Log Buffer (4096 bytes):
*Mar  1 00:01:12.341: %LINK-3-UPDOWN: Interface GigabitEthernet0/0, changed state to up
*Mar  1 00:01:13.341: %LINEPROTO-5-UPDOWN: Line protocol on Interface GigabitEthernet0/0, changed state to up
*Mar  1 00:05:44.112: %SYS-5-CONFIG_I: Configured from console by console
*Mar  1 00:12:01.200: %OSPF-5-ADJCHG: Process 1, Nbr 2.2.2.2 on GigabitEthernet0/1 from LOADING to FULL, Loading Done""";

  static const _baseRunningConfig = r"""
Building configuration...

Current configuration : 1842 bytes
!
version 15.2
service timestamps debug datetime msec
no service password-encryption
!
hostname __HOSTNAME__
!
enable secret 5 $1$mERr$hx5rVt7rPNoS4wqbXKX7m0
!
ip routing
!
interface GigabitEthernet0/0
 description UPLINK-WAN
 ip address 192.168.1.1 255.255.255.0
 no shutdown
!
interface GigabitEthernet0/1
 description TO-R2
 ip address 10.0.0.1 255.255.255.252
 no shutdown
!
interface GigabitEthernet0/2
 description UNUSED
 shutdown
!
interface GigabitEthernet0/3
 ip address 172.16.10.1 255.255.255.0
 no shutdown
!
interface Vlan10
 ip address 10.10.10.1 255.255.255.0
!
interface Vlan20
 ip address 10.20.20.1 255.255.255.0
!
router ospf 1
 router-id 1.1.1.1
 network 10.0.0.0 0.0.0.3 area 0
 network 10.10.10.0 0.0.0.255 area 0
__EXTRA_OSPF__!
router bgp 65001
 bgp router-id 1.1.1.1
 neighbor 10.0.0.2 remote-as 65001
 neighbor 203.0.113.1 remote-as 65000
 neighbor 192.0.2.8 remote-as 65002
!
ip route 0.0.0.0 0.0.0.0 192.168.1.254
!
access-list 100 permit tcp any any eq www
access-list 100 permit tcp any any eq 443
access-list 100 deny ip 10.30.30.0 0.0.0.255 any
access-list 100 permit ip any any
!
line vty 0 4
 login local
 transport input ssh
!
end""";

  String get showRunningConfig {
    var cfg = _baseRunningConfig.replaceFirst('__HOSTNAME__', hostname);

    final extra = _extraOspfNetworks.isEmpty
        ? ''
        : '${_extraOspfNetworks.map((n) => ' $n').join('\n')}\n';
    cfg = cfg.replaceFirst('__EXTRA_OSPF__', extra);

    for (final e in _ifOverrides.entries) {
      final name = e.key;
      final st = e.value;
      final block = StringBuffer('interface $name\n');
      if (st.description != null) {
        block.writeln(' description ${st.description}');
      }
      if (st.ip != null && st.mask != null) {
        block.writeln(' ip address ${st.ip} ${st.mask}');
      }
      if (st.shutdown == false) {
        block.writeln(' no shutdown');
      } else if (st.shutdown == true) {
        block.writeln(' shutdown');
      }
      final pattern = RegExp(
        'interface ${RegExp.escape(name)}\\n(?:(?!interface |router |!).*\\n)*',
        multiLine: true,
      );
      cfg = cfg.replaceFirst(pattern, '$block');
    }
    return cfg;
  }

  static const _userHelp = """
Exec commands:
  enable          Turn on privileged commands
  exit            Exit from the EXEC
  show            Show running system information
  ?               This help""";

  static const _privHelp = """
Exec commands:
  configure       Enter configuration mode
  disable         Turn off privileged commands
  enable          Turn on privileged commands
  exit            Exit from the EXEC
  show            Show running system information
  ?               This help""";

  static const _configHelp = """
Configure commands:
  do              To run exec commands in config mode
  end             Exit configuration mode
  exit            Exit from config mode
  hostname        Set system's network name
  interface       Select an interface to configure
  router          Router configuration (ospf)
  ?               This help""";

  static const _configIfHelp = """
Interface configuration commands:
  do              To run exec commands in config mode
  exit            Exit from interface configuration
  ip              Interface Internet Protocol config
  no              Negate a command (no shutdown)
  shutdown        Shutdown the selected interface
  ?               This help""";

  static const _configRouterHelp = """
Router configuration commands:
  do              To run exec commands in config mode
  exit            Exit from router configuration
  network         Enable routing on an IP network
  router-id       router-id for this OSPF process
  ?               This help""";

  static const _showHelp = """
  access-lists    Access lists (show access-lists)
  cdp             CDP information (use: show cdp neighbors)
  etherchannel    EtherChannel (use: show etherchannel summary)
  interfaces      Interface status (show interfaces status)
  ip              IP information (interface, route, ospf, bgp, dhcp, nat)
  logging         Show the contents of logging buffers
  running-config  Current operating configuration
  spanning-tree   Spanning tree (show spanning-tree vlan 10)
  vlan            VLAN information (use: show vlan brief)""";

  static const _commands = <String>[
    'enable',
    'disable',
    'exit',
    'end',
    'configure terminal',
    'hostname',
    'show ip interface brief',
    'show vlan brief',
    'show ip route',
    'show ip route ospf',
    'show etherchannel summary',
    'show cdp neighbors',
    'show ip ospf neighbor',
    'show ip bgp summary',
    'show running-config',
    'show spanning-tree vlan',
    'show interfaces status',
    'show ip dhcp binding',
    'show ip nat translations',
    'show access-lists',
    'show logging',
  ];

  static const _privilegedOnly = <String>{
    'configure terminal',
    'disable',
    'show running-config',
  };

  /// Execute one line of user input. Returns device output (may be empty).
  String exec(String raw) {
    var line = raw.trim();
    if (line.isEmpty) return '';

    final doPrefix =
        (privilege == IosPrivilege.config ||
            privilege == IosPrivilege.configIf ||
            privilege == IosPrivilege.configRouter) &&
        (line.toLowerCase().startsWith('do ') || line.toLowerCase() == 'do');
    if (doPrefix) {
      line = line.substring(2).trim();
      if (line.isEmpty) return incomplete;
      return _execExec(line, asPrivileged: true);
    }

    if (line == '?' || line.toLowerCase() == 'help') {
      return _helpFor(privilege);
    }

    final lower = line.toLowerCase();
    if (lower == 'show?' || lower == 'show ?' || lower == 'sh ?') {
      return _showHelp;
    }
    if (lower.endsWith(' ?') || lower.endsWith('?')) {
      final trimmedQ = lower.endsWith(' ?')
          ? line.substring(0, line.length - 2).trim()
          : line.substring(0, line.length - 1).trim();
      if (trimmedQ.toLowerCase() == 'show' || trimmedQ.toLowerCase() == 'sh') {
        return _showHelp;
      }
      return _helpFor(privilege);
    }

    if (privilege == IosPrivilege.config ||
        privilege == IosPrivilege.configIf ||
        privilege == IosPrivilege.configRouter) {
      return _execConfig(line);
    }
    return _execExec(line, asPrivileged: privilege == IosPrivilege.privileged);
  }

  String _helpFor(IosPrivilege p) {
    switch (p) {
      case IosPrivilege.user:
        return _userHelp;
      case IosPrivilege.privileged:
        return _privHelp;
      case IosPrivilege.config:
        return _configHelp;
      case IosPrivilege.configIf:
        return _configIfHelp;
      case IosPrivilege.configRouter:
        return _configRouterHelp;
    }
  }

  String _execConfig(String line) {
    final tokens = _tokens(line);
    if (tokens.isEmpty) return '';

    if (_isCmd(tokens, 'end')) {
      privilege = IosPrivilege.privileged;
      _configIf = null;
      _ospfProcess = null;
      return '';
    }

    if (_isCmd(tokens, 'exit')) {
      if (privilege == IosPrivilege.configIf ||
          privilege == IosPrivilege.configRouter) {
        privilege = IosPrivilege.config;
        _configIf = null;
        _ospfProcess = null;
      } else {
        privilege = IosPrivilege.privileged;
      }
      return '';
    }

    if (privilege == IosPrivilege.configIf) {
      return _execConfigIf(tokens, line);
    }
    if (privilege == IosPrivilege.configRouter) {
      return _execConfigRouter(tokens);
    }

    // Global config
    if (tokens.first.toLowerCase().startsWith('host')) {
      if (tokens.length < 2) return incomplete;
      final parts = line.trim().split(RegExp(r'\s+'));
      hostname = parts[1];
      return '';
    }

    if (tokens.first.toLowerCase().startsWith('int')) {
      if (tokens.length < 2) return incomplete;
      final name = _normalizeInterface(tokens.sublist(1).join(''));
      if (name == null) return invalid;
      _configIf = name;
      privilege = IosPrivilege.configIf;
      _ifOverrides.putIfAbsent(name, _IfState.new);
      return '';
    }

    if (tokens.first.toLowerCase().startsWith('router')) {
      if (tokens.length < 2) return incomplete;
      if (!tokens[1].toLowerCase().startsWith('ospf')) return invalid;
      if (tokens.length < 3) return incomplete;
      final pid = int.tryParse(tokens[2]);
      if (pid == null) return invalid;
      _ospfProcess = pid;
      privilege = IosPrivilege.configRouter;
      return '';
    }

    return invalid;
  }

  String _execConfigIf(List<String> tokens, String line) {
    final ifName = _configIf;
    if (ifName == null) return invalid;
    final st = _ifOverrides.putIfAbsent(ifName, _IfState.new);

    if (tokens.first == 'no') {
      if (tokens.length >= 2 && tokens[1].startsWith('shut')) {
        st.shutdown = false;
        return '';
      }
      return invalid;
    }
    if (tokens.first.startsWith('shut')) {
      st.shutdown = true;
      return '';
    }
    if (tokens.first == 'ip') {
      if (tokens.length >= 2 && tokens[1].startsWith('add')) {
        if (tokens.length < 4) return incomplete;
        st.ip = tokens[2];
        st.mask = tokens[3];
        return '';
      }
      return incomplete;
    }
    if (tokens.first.startsWith('desc')) {
      final parts = line.trim().split(RegExp(r'\s+'));
      if (parts.length < 2) return incomplete;
      st.description = parts.sublist(1).join(' ');
      return '';
    }
    return invalid;
  }

  String _execConfigRouter(List<String> tokens) {
    if (tokens.first.startsWith('network')) {
      if (tokens.length < 4) return incomplete;
      // network <ip> <wildcard> area <id>
      final areaIdx = tokens.indexWhere((t) => t.startsWith('area'));
      if (areaIdx < 0 || areaIdx + 1 >= tokens.length) return incomplete;
      final net =
          'network ${tokens[1]} ${tokens[2]} area ${tokens[areaIdx + 1]}';
      if (!_extraOspfNetworks.contains(net) &&
          !showRunningConfig.contains(net)) {
        _extraOspfNetworks.add(net);
      }
      return '';
    }
    if (tokens.first.startsWith('router-id') ||
        (tokens.length >= 2 &&
            tokens[0].startsWith('router') &&
            tokens[1].startsWith('id'))) {
      return ''; // accept but keep canned RID
    }
    return invalid;
  }

  String? _normalizeInterface(String raw) {
    final s = raw.toLowerCase().replaceAll(' ', '');
    final map = <String, String>{
      'gi0/0': 'GigabitEthernet0/0',
      'gigabitethernet0/0': 'GigabitEthernet0/0',
      'g0/0': 'GigabitEthernet0/0',
      'gi0/1': 'GigabitEthernet0/1',
      'gigabitethernet0/1': 'GigabitEthernet0/1',
      'g0/1': 'GigabitEthernet0/1',
      'gi0/2': 'GigabitEthernet0/2',
      'gigabitethernet0/2': 'GigabitEthernet0/2',
      'g0/2': 'GigabitEthernet0/2',
      'gi0/3': 'GigabitEthernet0/3',
      'gigabitethernet0/3': 'GigabitEthernet0/3',
      'g0/3': 'GigabitEthernet0/3',
      'vlan10': 'Vlan10',
      'vlan20': 'Vlan20',
      'lo0': 'Loopback0',
      'loopback0': 'Loopback0',
    };
    return map[s];
  }

  String _execExec(String line, {required bool asPrivileged}) {
    // Support "show ... | include PATTERN"
    String? includeFilter;
    final pipeIdx = line.indexOf('|');
    var cmdLine = line;
    if (pipeIdx >= 0) {
      final after = line.substring(pipeIdx + 1).trim();
      final afterTok = _tokens(after);
      if (afterTok.isNotEmpty && afterTok.first.startsWith('inc')) {
        if (afterTok.length < 2) return incomplete;
        includeFilter = afterTok.sublist(1).join(' ');
        cmdLine = line.substring(0, pipeIdx).trim();
      } else {
        return invalid;
      }
    }

    var tokens = _tokens(cmdLine);
    if (tokens.isEmpty) return '';

    if (_isCmd(tokens, 'enable')) {
      privilege = IosPrivilege.privileged;
      return '';
    }
    if (_isCmd(tokens, 'disable')) {
      if (!asPrivileged) return invalid;
      privilege = IosPrivilege.user;
      return '';
    }
    if (_isCmd(tokens, 'exit') || _isCmd(tokens, 'logout')) {
      if (privilege == IosPrivilege.privileged) {
        privilege = IosPrivilege.user;
      }
      return '';
    }
    if (_isCmd(tokens, 'end')) {
      if (privilege == IosPrivilege.config ||
          privilege == IosPrivilege.configIf ||
          privilege == IosPrivilege.configRouter) {
        privilege = IosPrivilege.privileged;
        _configIf = null;
        _ospfProcess = null;
      }
      return '';
    }

    // Normalize common singular aliases
    if (tokens.length >= 2 &&
        tokens[0].startsWith('sh') &&
        tokens[1] == 'access-list') {
      tokens = [...tokens];
      tokens[1] = 'access-lists';
    }
    if (tokens.length >= 4 &&
        tokens[0].startsWith('sh') &&
        tokens[1] == 'ip' &&
        tokens[2] == 'nat' &&
        tokens[3].startsWith('translation') &&
        tokens[3] != 'translations') {
      tokens = [...tokens];
      tokens[3] = 'translations';
    }

    // Special: show spanning-tree vlan [id]
    if (_matchesPrefix(tokens, ['show', 'spanning-tree', 'vlan']) ||
        _matchesPrefix(tokens, ['sh', 'spanning-tree', 'vlan']) ||
        _matchesPrefix(tokens, ['show', 'span', 'vlan']) ||
        _matchesPrefix(tokens, ['sh', 'span', 'vlan'])) {
      if (tokens.length < 3) return incomplete;
      // Need at least show spanning-tree vlan
      final vlanTok = tokens.length >= 4 ? tokens[3] : null;
      if (vlanTok == null) return incomplete;
      if (vlanTok != '10') {
        return 'Spanning tree instance(s) for vlan $vlanTok does not exist.';
      }
      return _applyInclude(showSpanningTreeVlan10, includeFilter);
    }

    final matches = _matchCommands(tokens);
    if (matches.isEmpty) return invalid;
    if (matches.length > 1) {
      final exact = matches
          .where((c) => c.split(' ').length == tokens.length)
          .toList();
      if (exact.length == 1) {
        return _applyInclude(
          _runCanonical(exact.single, asPrivileged: asPrivileged),
          includeFilter,
        );
      }
      if (exact.isEmpty) return incomplete;
      return ambiguous;
    }
    final canonical = matches.single;
    if (tokens.length < canonical.split(' ').length) return incomplete;
    return _applyInclude(
      _runCanonical(canonical, asPrivileged: asPrivileged),
      includeFilter,
    );
  }

  bool _matchesPrefix(List<String> tokens, List<String> want) {
    if (tokens.length < want.length) return false;
    for (var i = 0; i < want.length; i++) {
      if (!want[i].startsWith(tokens[i])) return false;
    }
    return true;
  }

  String _applyInclude(String out, String? filter) {
    if (filter == null || filter.isEmpty) return out;
    if (out == notAuth ||
        out == invalid ||
        out == incomplete ||
        out == ambiguous) {
      return out;
    }
    final needle = filter.toLowerCase();
    final lines = out.split('\n').where((l) {
      return l.toLowerCase().contains(needle);
    });
    return lines.join('\n');
  }

  String _runCanonical(String canonical, {required bool asPrivileged}) {
    if (canonical == 'configure terminal') {
      if (!asPrivileged) return notAuth;
      privilege = IosPrivilege.config;
      return 'Enter configuration commands, one per line. End with CNTL/Z.';
    }
    if (canonical == 'hostname') return incomplete;
    if (canonical == 'enable') {
      privilege = IosPrivilege.privileged;
      return '';
    }
    if (canonical == 'disable') {
      if (!asPrivileged) return invalid;
      privilege = IosPrivilege.user;
      return '';
    }
    if (canonical == 'exit' || canonical == 'end') {
      if (privilege == IosPrivilege.privileged) {
        privilege = IosPrivilege.user;
      }
      return '';
    }
    if (_privilegedOnly.contains(canonical) && !asPrivileged) {
      return notAuth;
    }
    switch (canonical) {
      case 'show ip interface brief':
        return _showIpInterfaceBriefLive();
      case 'show vlan brief':
        return showVlanBrief;
      case 'show ip route':
        return showIpRoute;
      case 'show ip route ospf':
        return showIpRouteOspf;
      case 'show etherchannel summary':
        return showEtherchannelSummary;
      case 'show cdp neighbors':
        return showCdpNeighbors;
      case 'show ip ospf neighbor':
        return showIpOspfNeighbor;
      case 'show ip bgp summary':
        return showIpBgpSummary;
      case 'show running-config':
        return showRunningConfig;
      case 'show spanning-tree vlan':
        return incomplete;
      case 'show interfaces status':
        return showInterfacesStatus;
      case 'show ip dhcp binding':
        return showIpDhcpBinding;
      case 'show ip nat translations':
        return showIpNatTranslations;
      case 'show access-lists':
        return showAccessLists;
      case 'show logging':
        return showLogging;
      default:
        return invalid;
    }
  }

  String _showIpInterfaceBriefLive() {
    var out = showIpInterfaceBrief;
    for (final e in _ifOverrides.entries) {
      final name = e.key;
      final st = e.value;
      if (st.ip == null && st.shutdown == null) continue;
      final lines = out.split('\n');
      for (var i = 0; i < lines.length; i++) {
        if (lines[i].startsWith(name.padRight(22).substring(0, name.length)) ||
            lines[i].startsWith(name)) {
          final ip = (st.ip ?? 'unassigned').padRight(15);
          final method = st.ip != null ? 'manual' : 'unset ';
          final status = st.shutdown == false
              ? 'up'
              : (st.shutdown == true ? 'administratively down' : 'down');
          final proto = st.shutdown == false ? 'up' : 'down';
          final statusPad = status == 'administratively down'
              ? 'administratively down'
              : status.padRight(22);
          lines[i] =
              '${name.padRight(22)}$ip YES $method $statusPad $proto';
          break;
        }
      }
      out = lines.join('\n');
    }
    return out;
  }

  bool _isCmd(List<String> tokens, String canonical) {
    final ct = canonical.split(' ');
    if (tokens.length != ct.length) return false;
    for (var i = 0; i < tokens.length; i++) {
      if (!ct[i].startsWith(tokens[i].toLowerCase())) return false;
    }
    return true;
  }

  List<String> _matchCommands(List<String> tokens) {
    return _commands.where((cmd) {
      final ct = cmd.split(' ');
      if (tokens.length > ct.length) return false;
      for (var i = 0; i < tokens.length; i++) {
        if (!ct[i].startsWith(tokens[i].toLowerCase())) return false;
      }
      return true;
    }).toList();
  }

  List<String> _tokens(String line) => line
      .toLowerCase()
      .split(RegExp(r'\s+'))
      .where((t) => t.isNotEmpty)
      .toList();
}

class _IfState {
  String? description;
  String? ip;
  String? mask;
  bool? shutdown;
}
