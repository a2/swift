// RUN: %empty-directory(%t)
// RUN: %target-swift-frontend -emit-module -o %t/UsingObjCStuff.swiftmodule -module-name UsingObjCStuff -I %t -I %S/Inputs/mixed_mode -swift-version 5 %S/Inputs/mixed_mode/UsingObjCStuff.swift
// RUN: %target-swift-frontend -emit-ir -I %t -I %S/Inputs/mixed_mode -module-name main -swift-version 4 %s | %FileCheck %s --check-prefix=CHECK --check-prefix=CHECK-%target-ptrsize --check-prefix=CHECK-V4 -DWORD=i%target-ptrsize
// RUN: %target-swift-frontend -emit-ir -I %t -I %S/Inputs/mixed_mode -module-name main -swift-version 5 %s | %FileCheck %s --check-prefix=CHECK --check-prefix=CHECK-%target-ptrsize --check-prefix=CHECK-V5 -DWORD=i%target-ptrsize

// REQUIRES: objc_interop

import UsingObjCStuff

public class SubButtHolder: ButtHolder {
  final var w: Float = 0

  override public func virtual() {}

  public func subVirtual() {}
}

public class SubSubButtHolder: SubButtHolder {
  public override func virtual() {}
  public override func subVirtual() {}
}

// CHECK-LABEL: define {{(protected )?}}{{(dllexport )?}}swiftcc void @"$S4main17accessFinalFields2ofyp_ypt14UsingObjCStuff10ButtHolderC_tF"
public func accessFinalFields(of holder: ButtHolder) -> (Any, Any) {

  // ButtHolder.y cannot be imported in Swift 4 mode, so make sure we use field
  // offset globals here.

  // CHECK-V4: [[OFFSET:%.*]] = load [[WORD]], [[WORD]]* @"$S14UsingObjCStuff10ButtHolderC1xSivpWvd"
  // CHECK-V4: [[INSTANCE_RAW:%.*]] = bitcast {{.*}} to i8*
  // CHECK-V4: getelementptr inbounds i8, i8* [[INSTANCE_RAW]], [[WORD]] [[OFFSET]]

  // CHECK-V4: [[OFFSET:%.*]] = load [[WORD]], [[WORD]]* @"$S14UsingObjCStuff10ButtHolderC1zSSvpWvd"
  // CHECK-V4: [[INSTANCE_RAW:%.*]] = bitcast {{.*}} to i8*
  // CHECK-V4: getelementptr inbounds i8, i8* [[INSTANCE_RAW]], [[WORD]] [[OFFSET]]

  // ButtHolder.y is correctly imported in Swift 5 mode, so we can use fixed offsets.

  // CHECK-V5: [[OFFSET:%.*]] = getelementptr inbounds %T14UsingObjCStuff10ButtHolderC, %T14UsingObjCStuff10ButtHolderC* %2, i32 0, i32 1

  // CHECK-V5: [[OFFSET:%.*]] = getelementptr inbounds %T14UsingObjCStuff10ButtHolderC, %T14UsingObjCStuff10ButtHolderC* %2, i32 0, i32 3

  return (holder.x, holder.z)
}

// CHECK-LABEL: define {{(protected )?}}{{(dllexport )?}}swiftcc void @"$S4main17accessFinalFields5ofSubyp_ypyptAA0F10ButtHolderC_tF"
public func accessFinalFields(ofSub holder: SubButtHolder) -> (Any, Any, Any) {
  // We should use the runtime-adjusted ivar offsets since we may not have
  // a full picture of the layout in mixed Swift language version modes.

  // ButtHolder.y cannot be imported in Swift 4 mode, so make sure we use field
  // offset globals here.

  // CHECK-V4: [[OFFSET:%.*]] = load [[WORD]], [[WORD]]* @"$S14UsingObjCStuff10ButtHolderC1xSivpWvd"
  // CHECK-V4: [[INSTANCE_RAW:%.*]] = bitcast {{.*}} to i8*
  // CHECK-V4: getelementptr inbounds i8, i8* [[INSTANCE_RAW]], [[WORD]] [[OFFSET]]

  // CHECK-V4: [[OFFSET:%.*]] = load [[WORD]], [[WORD]]* @"$S14UsingObjCStuff10ButtHolderC1zSSvpWvd"
  // CHECK-V4: [[INSTANCE_RAW:%.*]] = bitcast {{.*}} to i8*
  // CHECK-V4: getelementptr inbounds i8, i8* [[INSTANCE_RAW]], [[WORD]] [[OFFSET]]

  // CHECK-V4: [[OFFSET:%.*]] = load [[WORD]], [[WORD]]* @"$S4main13SubButtHolderC1wSfvpWvd"

  // CHECK-V4: [[INSTANCE_RAW:%.*]] = bitcast {{.*}} to i8*
  // CHECK-V4: getelementptr inbounds i8, i8* [[INSTANCE_RAW]], [[WORD]] [[OFFSET]]
  
  // ButtHolder.y is correctly imported in Swift 5 mode, so we can use fixed offsets.

  // CHECK-V5: [[SELF:%.*]] = bitcast %T4main13SubButtHolderC* %3 to %T14UsingObjCStuff10ButtHolderC*
  // CHECK-V5: [[OFFSET:%.*]] = getelementptr inbounds %T14UsingObjCStuff10ButtHolderC, %T14UsingObjCStuff10ButtHolderC* [[SELF]], i32 0, i32 1

  // CHECK-V5: [[SELF:%.*]] = bitcast %T4main13SubButtHolderC* %3 to %T14UsingObjCStuff10ButtHolderC*
  // CHECK-V5: [[OFFSET:%.*]] = getelementptr inbounds %T14UsingObjCStuff10ButtHolderC, %T14UsingObjCStuff10ButtHolderC* [[SELF]], i32 0, i32 3

  // CHECK-V5: [[OFFSET:%.*]] = getelementptr inbounds %T4main13SubButtHolderC, %T4main13SubButtHolderC* %3, i32 0, i32 4

  return (holder.x, holder.z, holder.w)
}

// CHECK-LABEL: define {{(protected )?}}{{(dllexport )?}}swiftcc void @"$S4main12invokeMethod2onyAA13SubButtHolderC_tF"
public func invokeMethod(on holder: SubButtHolder) {
  // CHECK-64: [[IMPL_ADDR:%.*]] = getelementptr inbounds {{.*}}, [[WORD]] 10
  // CHECK-32: [[IMPL_ADDR:%.*]] = getelementptr inbounds {{.*}}, [[WORD]] 13
  // CHECK: [[IMPL:%.*]] = load {{.*}} [[IMPL_ADDR]]
  // CHECK: call swiftcc void [[IMPL]]
  holder.virtual()
  // CHECK-64: [[IMPL_ADDR:%.*]] = getelementptr inbounds {{.*}}, [[WORD]] 15
  // CHECK-32: [[IMPL_ADDR:%.*]] = getelementptr inbounds {{.*}}, [[WORD]] 18
  // CHECK: [[IMPL:%.*]] = load {{.*}} [[IMPL_ADDR]]
  // CHECK: call swiftcc void [[IMPL]]
  holder.subVirtual()
}

// CHECK-V4-LABEL: define internal swiftcc %swift.metadata_response @"$S4main13SubButtHolderCMr"(%swift.type*, i8*, i8**)
// CHECK-V4:   call void @swift_initClassMetadata(

// CHECK-V4-LABEL: define internal swiftcc %swift.metadata_response @"$S4main03SubB10ButtHolderCMr"(%swift.type*, i8*, i8**)
// CHECK-V4:   call void @swift_initClassMetadata(

