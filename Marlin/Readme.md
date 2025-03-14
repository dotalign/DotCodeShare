# Programmatically Loading a Profile Inside the DotAlign Sidebar

The function `loadInDotAlign` allows you to specify a company or person and have their profile loaded inside the DotAlign sidebar.

## Usage

The following is an example of how it should be called:

```javascript
loadInDotAlign('companies/dotalign.com');
loadInDotAlign('people/jaspreet@dotalign.com');
```

> **Note:** There is no forward slash at the beginning of the parameter.

Email addresses and domains are preferred, but you can also pass in the name of the person or company. Please note that name-based input can lead to inaccurate matches.

```javascript
loadInDotAlign('companies/DotAlign, Inc.');
loadInDotAlign('people/Jaspreet Bakshi');
```
