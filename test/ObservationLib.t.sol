// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import { console2 } from "forge-std/console2.sol";

import { BaseSetup } from "test/utils/BaseSetup.sol";
import { ObservationLib, MAX_CARDINALITY } from "src/libraries/ObservationLib.sol";
import { RingBufferLib } from "ring-buffer-lib/RingBufferLib.sol";

contract ObservationLibTest is BaseSetup {
  ObservationLib.Observation[MAX_CARDINALITY] observations;

  /* ============ helpers ============ */

  /**
   *
   * @param _timestamps the timestamps to create
   */
  function populateObservations(uint32[] memory _timestamps) public {
    for (uint i; i < _timestamps.length; i++) {
      observations[RingBufferLib.wrap(i, MAX_CARDINALITY)] = ObservationLib.Observation({
        timestamp: _timestamps[i],
        balance: 0,
        cumulativeBalance: 0
      });
    }
  }

  /* ============ binarySearch ============ */

  function testBinarySearch_HappyPath_beforeOrAt() public {
    uint32[] memory t = new uint32[](6);
    t[0] = 1;
    t[1] = 2;
    t[2] = 3;
    t[3] = 4;
    t[4] = 5;
    t[5] = 6;
    populateObservations(t);
    uint24 newestObservationIndex = 5;
    uint24 oldestObservationIndex = 0;
    uint32 target = 3;
    uint16 cardinality = uint16(t.length);
    uint32 time = 100;

    (
      ObservationLib.Observation memory beforeOrAt,
      ObservationLib.Observation memory afterOrAt
    ) = ObservationLib.binarySearch(
        observations,
        newestObservationIndex,
        oldestObservationIndex,
        target,
        cardinality,
        time
      );

    assertEq(beforeOrAt.timestamp, target);
    assertEq(afterOrAt.timestamp, target + 1);
  }

  function testBinarySearch_HappyPath_afterOrAt() public {
    uint32[] memory t = new uint32[](6);
    t[0] = 1;
    t[1] = 2;
    t[2] = 3;
    t[3] = 4;
    t[4] = 5;
    t[5] = 6;
    populateObservations(t);
    uint24 newestObservationIndex = 5;
    uint24 oldestObservationIndex = 0;
    uint32 target = 4;
    uint16 cardinality = uint16(t.length);
    uint32 time = 100;

    (
      ObservationLib.Observation memory beforeOrAt,
      ObservationLib.Observation memory afterOrAt
    ) = ObservationLib.binarySearch(
        observations,
        newestObservationIndex,
        oldestObservationIndex,
        target,
        cardinality,
        time
      );

    assertEq(beforeOrAt.timestamp, target - 1);
    assertEq(afterOrAt.timestamp, target);
  }

  // Outside of range
  function testFailBinarySearch_OneItem_TargetBefore() public {
    uint32[] memory t = new uint32[](1);
    t[0] = 10;
    populateObservations(t);
    uint24 newestObservationIndex = 0;
    uint24 oldestObservationIndex = 0;
    uint32 target = 5;
    uint16 cardinality = uint16(t.length);
    uint32 time = 100;

    ObservationLib.binarySearch(
      observations,
      newestObservationIndex,
      oldestObservationIndex,
      target,
      cardinality,
      time
    );
  }

  function testBinarySearch_OneItem_TargetExact() public {
    uint32[] memory t = new uint32[](1);
    t[0] = 10;
    populateObservations(t);
    uint24 newestObservationIndex = 0;
    uint24 oldestObservationIndex = 0;
    uint32 target = 10;
    uint16 cardinality = uint16(t.length);
    uint32 time = 100;

    (
      ObservationLib.Observation memory beforeOrAt,
      ObservationLib.Observation memory afterOrAt
    ) = ObservationLib.binarySearch(
        observations,
        newestObservationIndex,
        oldestObservationIndex,
        target,
        cardinality,
        time
      );

    assertEq(beforeOrAt.timestamp, 10);
    assertEq(afterOrAt.timestamp, 10);
  }

  // Outside of range
  function testFailBinarySearch_OneItem_TargetAfter() public {
    uint32[] memory t = new uint32[](1);
    t[0] = 10;
    populateObservations(t);
    uint24 newestObservationIndex = 0;
    uint24 oldestObservationIndex = 0;
    uint32 target = 15;
    uint16 cardinality = uint16(t.length);
    uint32 time = 100;

    ObservationLib.binarySearch(
      observations,
      newestObservationIndex,
      oldestObservationIndex,
      target,
      cardinality,
      time
    );
  }

  function testBinarySearch_TwoItems_TargetStart() public {
    uint32[] memory t = new uint32[](2);
    t[0] = 10;
    t[1] = 20;
    populateObservations(t);
    uint24 newestObservationIndex = 1;
    uint24 oldestObservationIndex = 0;
    uint32 target = 10;
    uint16 cardinality = uint16(t.length);
    uint32 time = 100;

    (
      ObservationLib.Observation memory beforeOrAt,
      ObservationLib.Observation memory afterOrAt
    ) = ObservationLib.binarySearch(
        observations,
        newestObservationIndex,
        oldestObservationIndex,
        target,
        cardinality,
        time
      );

    assertEq(beforeOrAt.timestamp, 10);
    assertEq(afterOrAt.timestamp, 20);
  }

  function testBinarySearch_TwoItems_TargetBetween() public {
    uint32[] memory t = new uint32[](2);
    t[0] = 10;
    t[1] = 20;
    populateObservations(t);
    uint24 newestObservationIndex = 1;
    uint24 oldestObservationIndex = 0;
    uint32 target = 15;
    uint16 cardinality = uint16(t.length);
    uint32 time = 100;

    (
      ObservationLib.Observation memory beforeOrAt,
      ObservationLib.Observation memory afterOrAt
    ) = ObservationLib.binarySearch(
        observations,
        newestObservationIndex,
        oldestObservationIndex,
        target,
        cardinality,
        time
      );

    assertEq(beforeOrAt.timestamp, 10);
    assertEq(afterOrAt.timestamp, 20);
  }

  function testBinarySearch_TwoItems_TargetEnd() public {
    uint32[] memory t = new uint32[](2);
    t[0] = 10;
    t[1] = 20;
    populateObservations(t);
    uint24 newestObservationIndex = 1;
    uint24 oldestObservationIndex = 0;
    uint32 target = 20;
    uint16 cardinality = uint16(t.length);
    uint32 time = 100;

    (
      ObservationLib.Observation memory beforeOrAt,
      ObservationLib.Observation memory afterOrAt
    ) = ObservationLib.binarySearch(
        observations,
        newestObservationIndex,
        oldestObservationIndex,
        target,
        cardinality,
        time
      );

    assertEq(beforeOrAt.timestamp, 10);
    assertEq(afterOrAt.timestamp, 20);
  }

  function testBinarySearch_ThreeItems_TargetStart() public {
    uint32[] memory t = new uint32[](3);
    t[0] = 10;
    t[1] = 20;
    t[2] = 30;
    populateObservations(t);
    uint24 newestObservationIndex = 2;
    uint24 oldestObservationIndex = 0;
    uint32 target = 10;
    uint16 cardinality = uint16(t.length);
    uint32 time = 100;

    (
      ObservationLib.Observation memory beforeOrAt,
      ObservationLib.Observation memory afterOrAt
    ) = ObservationLib.binarySearch(
        observations,
        newestObservationIndex,
        oldestObservationIndex,
        target,
        cardinality,
        time
      );

    assertEq(beforeOrAt.timestamp, 10);
    assertEq(afterOrAt.timestamp, 20);
  }

  function testBinarySearch_ThreeItems_TargetBetween() public {
    uint32[] memory t = new uint32[](3);
    t[0] = 10;
    t[1] = 20;
    t[2] = 30;
    populateObservations(t);
    uint24 newestObservationIndex = 2;
    uint24 oldestObservationIndex = 0;
    uint32 target = 20;
    uint16 cardinality = uint16(t.length);
    uint32 time = 100;

    (
      ObservationLib.Observation memory beforeOrAt,
      ObservationLib.Observation memory afterOrAt
    ) = ObservationLib.binarySearch(
        observations,
        newestObservationIndex,
        oldestObservationIndex,
        target,
        cardinality,
        time
      );

    assertEq(beforeOrAt.timestamp, 20);
    assertEq(afterOrAt.timestamp, 30);
  }

  function testBinarySearch_ThreeItems_TargetEnd() public {
    uint32[] memory t = new uint32[](3);
    t[0] = 10;
    t[1] = 20;
    t[2] = 30;
    populateObservations(t);
    uint24 newestObservationIndex = 2;
    uint24 oldestObservationIndex = 0;
    uint32 target = 30;
    uint16 cardinality = uint16(t.length);
    uint32 time = 100;

    (
      ObservationLib.Observation memory beforeOrAt,
      ObservationLib.Observation memory afterOrAt
    ) = ObservationLib.binarySearch(
        observations,
        newestObservationIndex,
        oldestObservationIndex,
        target,
        cardinality,
        time
      );

    assertEq(beforeOrAt.timestamp, 20);
    assertEq(afterOrAt.timestamp, 30);
  }
}