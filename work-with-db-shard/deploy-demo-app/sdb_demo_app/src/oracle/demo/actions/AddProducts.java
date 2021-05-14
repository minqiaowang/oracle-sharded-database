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
import oracle.demo.Product;

import java.util.ArrayList;
import java.util.List;

public class AddProducts extends Actor.Action
{
    @Override
    public void run() throws ApplicationException {
        final List<Product> productList = new ArrayList<>();

        for (int i = 0; i < 3; ++i) {
            productList.add(new Product(random));
        }

        Product.addProducts(app, productList);
    }
}
