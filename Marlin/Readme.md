#Programmaticlaly loading a profile inside the DotAlign sidebar 

The function loadInDotAlign allows you to specify a company or person and have their profile loaded inside the DotAlign sidebar. 

The following is an example of how it should be called: 

loadInDotAlign('companies/dotalign.com')
loadInDotAlign('people/jaspreet@dotalign.com')

Note that there is no forward slash at the beginning of the parameter. 

Email addresses and domains are preferred, but you can also pass in the name of the person or company. Please note that name-based input can lead to inaccurate matches.

loadInDotAlign('companies/DotAlign, Inc.')
loadInDotAlign('people/Jaspreet Bakshi')
