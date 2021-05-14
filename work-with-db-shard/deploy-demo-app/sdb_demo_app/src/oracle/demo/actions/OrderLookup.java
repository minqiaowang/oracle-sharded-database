/*
** Oracle Sharding Demo
**
** Copyright (c) 2017 Oracle and/or its affiliates. All rights reserved.
** Licensed under the Universal Permissive License v 1.0 as shown at 
**   http://oss.oracle.com/licenses/upl 
*/

package oracle.demo.actions;

import oracle.demo.Actor;
import oracle.demo.ApplicationException;

public class OrderLookup extends CustomerAction
{
    @Override
    public void run() throws ApplicationException
    {
        /* Generate customer name and lookup customer */
        super.run();

        /* If not exists, exit */
        if (!customer.exists) {
            session.selectRandomProducts(random);
        }

        session.getOrders(resultSet -> { /* Do nothing! */ });
    }
}
