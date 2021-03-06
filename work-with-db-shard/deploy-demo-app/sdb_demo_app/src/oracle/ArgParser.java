/*
** Oracle Sharding Demo
**
** Copyright (c) 2017 Oracle and/or its affiliates. All rights reserved.
** Licensed under the Universal Permissive License v 1.0 as shown at 
**   http://oss.oracle.com/licenses/upl 
*/

package oracle;

import java.io.FileNotFoundException;
import java.io.FileReader;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;
import java.util.Properties;

public class ArgParser
{
    public final List<Properties> propertyFiles = new ArrayList<>();

    public ArgParser(String [] args)
    {
        for (String s : args)
        {
            if (s.endsWith(".properties"))
            {
                try {
                    Properties properties = new Properties(System.getProperties());
                    properties.load(new FileReader(s));
                    propertyFiles.add(properties);
                } catch (IOException e) {
                    /* Make fatal! */
                    throw new RuntimeException(e);
                }
            }
        }
    }
}
