/// Canned Cisco IOS-like CLI for Labs. Not a real device — deterministic output.
enum IosPrivilege { user, privileged, config }

class IosCli {
  IosCli({this.hostname = 'SW1'});

  String hostname;
  IosPrivilege privilege = IosPrivilege.user;

  String get prompt {
    switch (privilege) {
      case IosPrivilege.user:
        return '$hostname>';
      case IosPrivilege.privileged:
        return '$hostname#';
      case IosPrivilege.config:
        return '$hostname(config)#';
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

  static const showRunningConfig = r"""
Building configuration...

Current configuration : 1842 bytes
!
version 15.2
service timestamps debug datetime msec
no service password-encryption
!
hostname SW1
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
!
router bgp 65001
 bgp router-id 1.1.1.1
 neighbor 10.0.0.2 remote-as 65001
 neighbor 203.0.113.1 remote-as 65000
 neighbor 192.0.2.8 remote-as 65002
!
ip route 0.0.0.0 0.0.0.0 192.168.1.254
!
line vty 0 4
 login local
 transport input ssh
!
end""";

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
  ?               This help""";

  static const _showHelp = """
  bgp             BGP information (use: show ip bgp summary)
  cdp             CDP information (use: show cdp neighbors)
  etherchannel    EtherChannel (use: show etherchannel summary)
  ip              IP information (interface, route, ospf, bgp)
  running-config  Current operating configuration
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
    'show etherchannel summary',
    'show cdp neighbors',
    'show ip ospf neighbor',
    'show ip bgp summary',
    'show running-config',
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
        privilege == IosPrivilege.config &&
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

    if (privilege == IosPrivilege.config) {
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
    }
  }

  String _execConfig(String line) {
    final tokens = _tokens(line);
    if (tokens.isEmpty) return '';
    if (_isCmd(tokens, 'end') || _isCmd(tokens, 'exit')) {
      privilege = IosPrivilege.privileged;
      return '';
    }
    if (tokens.first.toLowerCase().startsWith('host')) {
      if (tokens.length < 2) return incomplete;
      hostname = tokens[1];
      return '';
    }
    return invalid;
  }

  String _execExec(String line, {required bool asPrivileged}) {
    final tokens = _tokens(line);
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
      if (privilege == IosPrivilege.config) {
        privilege = IosPrivilege.privileged;
      }
      return '';
    }

    final matches = _matchCommands(tokens);
    if (matches.isEmpty) return invalid;
    if (matches.length > 1) {
      final exact = matches
          .where((c) => c.split(' ').length == tokens.length)
          .toList();
      if (exact.length == 1) {
        return _runCanonical(exact.single, asPrivileged: asPrivileged);
      }
      if (exact.isEmpty) return incomplete;
      return ambiguous;
    }
    final canonical = matches.single;
    if (tokens.length < canonical.split(' ').length) return incomplete;
    return _runCanonical(canonical, asPrivileged: asPrivileged);
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
        return showIpInterfaceBrief;
      case 'show vlan brief':
        return showVlanBrief;
      case 'show ip route':
        return showIpRoute;
      case 'show etherchannel summary':
        return showEtherchannelSummary;
      case 'show cdp neighbors':
        return showCdpNeighbors;
      case 'show ip ospf neighbor':
        return showIpOspfNeighbor;
      case 'show ip bgp summary':
        return showIpBgpSummary;
      case 'show running-config':
        return showRunningConfig.replaceFirst(
          'hostname SW1',
          'hostname $hostname',
        );
      default:
        return invalid;
    }
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
