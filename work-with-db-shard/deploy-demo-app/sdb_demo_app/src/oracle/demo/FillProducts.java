/*
** Oracle Sharding Demo
**
** Copyright (c) 2017 Oracle and/or its affiliates. All rights reserved.
** Licensed under the Universal Permissive License v 1.0 as shown at 
**   http://oss.oracle.com/licenses/upl 
*/

package oracle.demo;

import oracle.ArgParser;

public class FillProducts {
    public static void main(String[] args) { new Main(new ArgParser(args)).fillProducts(); }
}
