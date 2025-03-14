const loadInDotAlign = (relativePath) => {
    const iframe = document.querySelector('#dotalignEmbedApp')
    if (!iframe) {
      console.error('The DotAlign iFrame was not found');
      return;
    }
  
    const { origin } = new URL(iframe.src);

    if (iframe.src === `${origin}/blank.html` || iframe.src.indexOf('options.html') > -1) {
      const parentNode = document.querySelector('.dotalign-iframe')
      const newIframe = iframe.cloneNode()
      newIframe.src = `${origin}/${relativePath}`
      parentNode.replaceChild(newIframe, iframe)
    } else {
      iframe.contentWindow.postMessage(`url:/${relativePath}`, iframe.src)
    }
    
    window.postMessage('da_open', '*');
}