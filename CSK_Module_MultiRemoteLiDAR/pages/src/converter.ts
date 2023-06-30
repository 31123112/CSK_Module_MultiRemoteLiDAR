export function convertToList(value) {
  return JSON.parse(value)
}

export function changeID(id) {
  const viewerElement = document.getElementById('Viewer3D');
  viewerElement.setAttribute('viewer-id', id);
  viewerElement.triggerResume();
  return id;
}