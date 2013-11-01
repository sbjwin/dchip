/*
 * Copyright (c) 2007-2013 Scott Lembcke and Howling Moon Software
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */
module dchip.cpPinJoint;

import std.string;

import dchip.constraints_util;
import dchip.chipmunk;
import dchip.cpBody;
import dchip.cpConstraint;
import dchip.chipmunk_types;

const cpConstraintClass* cpPinJointGetClass();

/// @private
struct cpPinJoint
{
    cpConstraint constraint;
    cpVect anchr1, anchr2;
    cpFloat dist;

    cpVect r1, r2;
    cpVect n;
    cpFloat nMass;

    cpFloat jnAcc;
    cpFloat bias;
}

/// Allocate a pin joint.
cpPinJoint* cpPinJointAlloc();

/// Initialize a pin joint.
cpPinJoint* cpPinJointInit(cpPinJoint* joint, cpBody* a, cpBody* b, cpVect anchr1, cpVect anchr2);

/// Allocate and initialize a pin joint.
cpConstraint* cpPinJointNew(cpBody* a, cpBody* b, cpVect anchr1, cpVect anchr2);

mixin CP_DefineConstraintProperty!("cpPinJoint", cpVect, "anchr1", "Anchr1");
mixin CP_DefineConstraintProperty!("cpPinJoint", cpVect, "anchr2", "Anchr2");
mixin CP_DefineConstraintProperty!("cpPinJoint", cpFloat, "dist", "Dist");