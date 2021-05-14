/*
** Oracle Sharding Demo
**
** Copyright (c) 2017 Oracle and/or its affiliates. All rights reserved.
** Licensed under the Universal Permissive License v 1.0 as shown at 
**   http://oss.oracle.com/licenses/upl 
*/

package oracle.demo.actions;

import oracle.Utils;
import oracle.demo.*;

public class CreateOrder extends CustomerAction
{
    static final double newOrderThreshold = 0.7;
    static final double newItemThreshold  = 0.8;

    @Override
    public void run() throws ApplicationException
    {
        /* Generate customer name and lookup customer */
        super.run();

        /* If not exists, create */
        if (!customer.exists)
        {
            generator.generateData();
            byte[] tmpPassword = customer.firstName.getBytes();

            try {
                session.createCustomer(tmpPassword);
            } finally {
                Utils.cleanArray(tmpPassword);
            }
        }

        do {
            /* Prepare an order */
            session.order();

            do {
                Session.ItemDef item;

                do {
                    /* Add items */
                    session.item(item = session.selectRandomProducts(random));

                /* This loop is just a hack for the case if select random returns null (it may) */
                } while (item == null);
            } while (random.nextDouble() > newItemThreshold);

            /* Submit order, this actually executes SQL */
            session.submit();
        } while (random.nextDouble() > newOrderThreshold);
    }
}
