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

public abstract class CustomerAction extends Actor.Action
{
    protected Session  session = null;
    protected Customer customer = null;
    protected CustomerGenerator generator = null;

    @Override
    public void run() throws ApplicationException
    {
        customer = new Customer();
        generator = new CustomerGenerator(random, customer);
        generator.generateName();

        session = new Session(customer, app);

        /* Lookup customer */
        try {
                /* Password is the first name for test purposes (ha-ha) */
            customer.tmpPassword = customer.firstName.getBytes();

                /* Check if exists */
            session.getCustomerInfo(customer.tmpPassword);
        } finally {
                /* Clean up password, we no longer need it */
            Utils.cleanArray(customer.tmpPassword);
        }
    }
}
