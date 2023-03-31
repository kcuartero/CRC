updateVisitorCount(); 

function updateVisitorCount() {
    fetch('https://kcuartero-gw-5u3b1jgg.uc.gateway.dev/count')
        .then(response => {
        return response.json();
        })
        .then(data => {
        console.log(data)
        document.getElementById("count").innerHTML = data.count;
        });
    }