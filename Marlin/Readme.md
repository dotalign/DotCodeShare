# Programmatically Loading a Company or Person Profile Inside the DotAlign Browser Extension

The DotAlign browser extension can be installed from 
<a href="https://chromewebstore.google.com/detail/dotalign/ofahkjbhcadlldpoahogjikmdoibbejh?hl=en-US&pli=1" target="_blank" rel="noopener noreferrer">here</a>.

The function `loadInDotAlign`, defined in the file `loadInDotAlign.js` allows you to specify a company or person and have their profile loaded inside the DotAlign sidebar. Once this method is available inside your code base, it can be used from whereever appropriate to open the DotAlign sidebar and load up a specific profile inside it.  

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

Please reach out to team@dotalign.com for any assistance. 
