function searchSuspectCooldownTable() {
    
    // Declare Variables
    var input, filter, table, tr, td, i, txtValue;
    var search_result_count = 0;

    // populate variables
    input  = document.getElementById("search_input");
    filter = input.value.toUpperCase();
    table  = document.getElementById("table_to_search");
    tr    = table.getElementsByTagName("tr");

    // Loop through all table rows, and hide those who don't match the query
    for (i = 0; i < tr.length; i++) {
        td = tr[i].getElementsByTagName("td")[1];
        if (td) {
            txtValue = td.textContent || td.innerText;
            if (txtValue.toUpperCase().indexOf(filter) > -1) {
                tr[i].style.display = "";
                search_result_count++;
            } else {
                tr[i].style.display = "none";
            }
        }
    }

    // set the inner html to  nothin when there is no search
    if (new String("") == filter) {
        document.getElementById("search_result_count").innerHTML = "";
    } else {
        document.getElementById("search_result_count").innerHTML = "Found " + search_result_count + " entries matching your search";
    }
}
