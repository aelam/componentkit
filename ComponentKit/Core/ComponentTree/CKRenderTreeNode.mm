/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import "CKRenderTreeNode.h"

#import <ComponentKit/CKThreadLocalComponentScope.h>

@implementation CKRenderTreeNode

// Base initializer
- (instancetype)initWithPreviousNode:(id<CKTreeNodeProtocol>)previousNode
                         scopeHandle:(CKComponentScopeHandle *)scopeHandle
{
  if (self = [super initWithPreviousNode:previousNode scopeHandle:scopeHandle]) {
    auto const threadLocalScope = CKThreadLocalComponentScope::currentScope();
    if (threadLocalScope != nullptr) {
      RCAssert(previousNode == nil || [previousNode isKindOfClass:[CKScopeTreeNode class]], @"previousNode should be a CKScopeTreeNode, but its class is: %@.", previousNode.class);
      // Push the new pair into the thread local.
      threadLocalScope->push({.node = self, .previousNode = previousNode});
    }
  }
  return self;
}

+ (void)didBuildComponentTree:(id<CKTreeNodeProtocol>)node
{
  auto const threadLocalScope = CKThreadLocalComponentScope::currentScope();
  if (threadLocalScope == nullptr) {
    return;
  }

  RCAssert(!threadLocalScope->stack.empty() && threadLocalScope->stack.top().node == (CKScopeTreeNode *)node, @"top.node (%@) is not equal to node (%@)", threadLocalScope->stack.top().node, node);

  // Pop the top element of the stack.
  threadLocalScope->pop();
}

- (void)didReuseRenderNode:(CKRenderTreeNode *)node
                 scopeRoot:(CKComponentScopeRoot *)scopeRoot
         previousScopeRoot:(CKComponentScopeRoot *)previousScopeRoot
{
  // Transfer the children vector from the reused node.
   _children = node->_children;

  for (auto const &child : _children) {
    if (child.key.type() == CKTreeNodeComponentKey::Type::parent) {
      [child.node didReuseWithParent:self inScopeRoot:scopeRoot];
    }
  }
}

@end
