let SOZinventory = {}

const INVENTORY_ENDPOINT = "https://soz-inventory"

const playerInventory = document.getElementById('player-inv')
const targetInventory = document.getElementById('target-inv')

dragula([playerInventory, targetInventory]).on('drop', function(el, target, source, sibling) {

  fetch(`${INVENTORY_ENDPOINT}/transfertItem`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: JSON.stringify({
      source: source.dataset.inventoryId,
      target: target.dataset.inventoryId,
      item: el.dataset,
    })
  })
    .then(function(response) {
      return response.json();
    })
    .then(function(json) {
      SOZinventory.setupContainer(
        document.querySelector(`section[data-inventory-id="${json.sourceInventory.id}"]`),
        json.sourceInventory
      )
      SOZinventory.setupContainer(
        document.querySelector(`section[data-inventory-id="${json.targetInventory.id}"]`),
        json.targetInventory
      )
    })
    .catch(function(err) {
      return false
    });

})


window.addEventListener("message", (event) => {
  switch (event.data.action) {
    case "openInventory":
      if (event.data.playerInventory === undefined || event.data.targetInventory === undefined) return

      document.querySelector('body').style.opacity = 1
      SOZinventory.setupContainer(playerInventory, event.data.playerInventory)
      SOZinventory.setupContainer(targetInventory, event.data.targetInventory)
      break;
    }
})

window.onkeyup = function (event) {
  if (event.key === 'Escape') {
    document.querySelector('body').style.opacity = 0
    fetch(`${INVENTORY_ENDPOINT}/closeNUI`, {  method: 'POST' });
  }
}

SOZinventory.setupContainer = function (container, inventory){
  container.innerHTML = ''
  container.dataset.inventoryId = inventory.id

  inventory.items.forEach(function(item, k){
    let itemNode = document.createElement('inventory-item')

    itemNode.dataset.slot = item.slot
    itemNode.dataset.name = item.name
    itemNode.dataset.label = item.label
    itemNode.dataset.amount = item.amount
    itemNode.dataset.description = item.description

    container.append(itemNode)
  })
}