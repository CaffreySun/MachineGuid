import 'package:machine_guid/machine_guid.dart';
import 'package:test/test.dart';

void main() {
  test('MachineGuid tests', () {
    final guid = getMachineGuid();
    assert(guid.isNotEmpty, 'getMachineGuid failed');
  });
}
