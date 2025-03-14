const loadInDotAlign = (relativePath) => {
    const iFrame = document.querySelector('#dotalignEmbedApp')
    
    if (!iFrame) {
      console.error('The DotAlign iFrame was not found');
      return;
    }
  
    const { origin } = new URL(iFrame.src);

    if (iFrame.src === `${origin}/blank.html` || iFrame.src.indexOf('options.html') > -1) {
      const parentNode = document.querySelector('.dotalign-iFrame')
      const newIFrame = iFrame.cloneNode()
      newIFrame.src = `${origin}/${relativePath}`
      parentNode.replaceChild(newIFrame, iFrame)
    } else {
      iFrame.contentWindow.postMessage(`url:/${relativePath}`, iFrame.src)
    }
    
    window.postMessage('da_open', '*');
}
