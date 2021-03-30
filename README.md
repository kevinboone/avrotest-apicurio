# avrotest-apicurio

A simple example of using Apache Avro to send structured objects 
-- Java objects, in this case -- through a message broker,
with the Avro schema stored in the Apicurio registry. This is
an extension of my `avrotest` example, and it produces exactly the same
output/

During the Maven build, Maven will retrieve the schema
whose ID is "Bear", and generate the java class `Bear.java` from it.
Both the raw schema (which is in Avro JSON format), and the Java class,
are needed at run-time.

The example
has two submodules, `sender` and `receiver`. You'll need to start
(after possibly obtaining) an AMQP-compatible broker, then run the
sender and receiver as described below.

You'll also need to download and run Apicurio, from 

https://github.com/Apicurio/apicurio-registry

I've tested this example with version 1.3.2 of Apicurio. 
Please be aware that Apicurio
changes almost daily, and this example may not work with other versions.

*This is not production-quality code*. It tries to demonstrate the simplest
possible way to use Avro and Apicurio in this setting, 
and has little regard for
error control or efficiency. There's a lot of duplication between the
sender and receiver, which is there to make each module self-contained.
It assumes that Apicurio is running in "dev" mode, which has no security.

The objects sent represent the properties of cartoon bears (because
why not?) The Avro schema is stored in the registry with ID `Bear`. 
During compilation, a
Maven plug-in downloads the scheme from the registry, and another
plug-in turns the schema JSON into the source file of a Java class
-- `Bear.java` -- that can store objects with the appropriate properties.

To use a broker protocol other than AMQP, you'll need to change the
connection factory in both the sender and receiver, at the necessary
client runtime libraries as dependencies in pom.xml, and edit the
broker properties in `avrotest.props`.` If you want to use an existing
schema registry, you'll probably need to change the schema URI in
pom.xml.

For a detailed description of how this application works, see:

https://kevinboone.me/avrotest-apicurio.html

Copyright (c)2021 Kevin Boone, GPL v3.0

## Setting up and preparing the broker

To run this example without changes, you'll need a message broker with
AMQP support, such as Apache Artemis. You can download Artemis
from the project website:

https://activemq.apache.org/components/artemis/download/

then install and run it as follows:

    $ unzip /path/to/apache-artemis-xxx.zip
    $ cd apache-artemis
    $ ./bin/artemis create avrotest
    $ cd avrotest
    $ ./bin/artemis run

The default TCP port will be 61616.

To configure the code to use the broker, edit `avrotest.props` to modify the
connection URI if necessary, and set the user and password. The "queue\_name"
property sets the name of the broker queue to use for the test. This code
doesn't care what the queue name is but, of course, you don't want to use
a name that will clash with anything else.

## Setting up and preparing apicurio

Download the Apicurio source from the link above. Build it using

$ ./mvnw clean package -DskipTests

Then run it in "dev" mode. 

$ ./mvnw quarkus:dev

Running in "dev" mode provides no authentication and no persistent 
database. The server will listen on port 8080, unless you change
the configuration. Note that the URL `http://localhost:8080/api` 
is hard-coded into `pom.xml`. so you'll need to change that if you
have to change the Apicurio configuration.

## Uploading the Avro schema to Apicurio

The schema is the file `schema/bear.schema`. I have purposely _not_
used `.avsc` as the filename extension, because the Avro Maven
plugin is too clever -- it will search the filesystem for 
`.avsc` files and, if it finds one, will use it in peference to the
version in the Apicurio registry. 

Point a web browser to Apicurio, typically `localhost:8080`. 
Select "Upload artifact". Fill in the "name" field as "Bear", but
leave the group name blank. Use the "Browse" button to location the file
`bear.schema`. See the screenshot in apicurio_upload.png.

*Note* running in "dev" mode provides no persistent storage. If you
restart Apicurio, you'll need to upload the schema again.

In practice, you'd probably upload the schema as part of the build
process, rather than using the console. The Apicurio Maven plugin 
can upload and modify schema artefacts, as well as donwloading them.
Alternatively, you could just invoke the Apicurio REST API directly, using
an HTTP client of some sort.

## Building

In the top-level directory:

    $ mvn package

This builds both the sender and the receiver. As part of the build, 
the schema will be retrieved from the Apicurio registry, and turned
into Java code.

## Running the receiver

    $ cd receiver
    $ java -jar target/receiver-0.1-jar-with-dependencies.jar

Note that the reciever needs to be run from the `receiver` directory,
because it's hard-coded to read the Avro schema and the configuration
properties from the directory above it.

The receiver waits for messages, and decodes them one at a time to
instances of class Bear, before printing the results to standard out.

## Running the sender 

    $ cd sender 
    $ java -jar target/sender-0.1-jar-with-dependencies.jar

Note that the sender needs to be run from the `sender` directory,
because it's hard-coded to read the Avro schema and the configuration
properties from the directory above it.

The sender creates several instances of class Bear, serializes them
using Avro, then sends them to a queue on the message broker.

## Notes

The Apicurio Maven plug-in has, at the time of writing, very poor 
error reporting. Most finds of problem seem to result in a 
NullPointerException, with little indication why. Check that Apicurio
is running, and has the relevant schema installed.

The build process places the schema and the automatically-generated
Java code in each of the `sender` and `receiver` source trees. 
To build completely from scratch, these entities must be removed
before running `mvn`. See the script `clean.sh`. 

Apicurio needs Java 11 or later. If you have multiple Java versions
installed, you'll need to specify the relevant `$PATH`. Setting
`JAVA_HOME` isn't sufficient on its own. For example:

    $ PATH=/usr/jdk-15/bin/:$PATH JAVA_HOME=/usr/jdk-15/ ./mvnw quarkus:dev


