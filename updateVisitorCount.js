updateVisitorCount(); 

function updateVisitorCount() {
    fetch('https://kcuart-gw-76btakhm.uc.gateway.dev/count')
        .then(response => {
        return response.json();
        })
        .then(data => {
        console.log(data)
        document.getElementById("count").innerHTML = data.count;
        });
    }