const loadInDotAlign = (relativePath) => {
    const iFrame = document.querySelector('#dotalignEmbedApp')

    if (!iFrame) {
      console.error('The DotAlign iFrame was not found');
      return;
    }

    const { origin } = new URL(iFrame.src);

    if (iFrame.src === `${origin}/blank.html` || iFrame.src.indexOf('options.html') > -1) {
      const parentNode = document.querySelector('.dotalign-iframe')
      const newIFrame = iFrame.cloneNode()
      newIFrame.src = `${origin}/${encodeURI(relativePath)}`
      parentNode.replaceChild(newIFrame, iFrame)
    } else {
      iFrame.contentWindow.postMessage(`url:/${encodeURI(relativePath)}`, iFrame.src)
    }

    window.postMessage('da_open', '*');
}
