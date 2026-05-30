// This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.
// If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.

class DraftRecoveryStatus {
  const DraftRecoveryStatus({
    required this.hasResidual,
    this.targetId,
    this.isNew = false,
    this.lastUpdated,
  });

  final bool hasResidual;
  final String? targetId;
  final bool isNew;
  final DateTime? lastUpdated;
}
