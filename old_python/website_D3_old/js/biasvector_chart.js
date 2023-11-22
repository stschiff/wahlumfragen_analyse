function biasvector_chart(svg) {
  var margin = {top: 50, right: 10, bottom: 10, left: 40},
      width = 600 - margin.left - margin.right,
      height = 300 - margin.top - margin.bottom;
  
  var partyColors = d3.scale.ordinal()
      .domain(["CDU", "SPD", "GRUENE", "FDP", "LINKE", "PIRATEN", "AFD"])
      .range(["black", "red", "green", "#FFD300", "pink", "orange", "steelblue"]);

  var x = d3.scale.ordinal().rangeRoundBands([0, width], .1).domain(partyColors.domain());
  var y = d3.scale.linear().range([height, 0]).domain([-2, 2]);

  var xAxis = d3.svg.axis().scale(x).orient("bottom"),
      yAxis = d3.svg.axis().scale(y).orient("left");
  
  var instituteList;
  var barData;
  var instituteSelect = "Forsa";
  
  svg.attr("width", width + margin.left + margin.right)
  .attr("height", height + margin.top + margin.bottom);
  
  var focus = svg.append("g")
    .attr("transform", "translate(" + margin.left + "," + margin.top + ")");
  
  d3.json("data/params.txt", function(error, data) {
    
    instituteList = data.institutes;
    barData = {};
    data.institutes.forEach(function(name, i) {
      barData[name] = {};
      data.parties.forEach(function(party, j) {
        if(party != "SONSTIGE")
          barData[name][party] = data.biasMatrix[i][j];
      });
    });
    
    drawBars();
    drawInstituteLegend();
    drawAxes();
  })
  
  function drawBars() {
    focus.selectAll(".bar")
        .data(partyColors.domain())
      .enter().append("rect")
        .attr("class", "bar")
        .attr("x", function(d) { return x(d); })
        .attr("width", x.rangeBand())
        .attr("y", function(d) { return y(Math.max(barData[instituteSelect][d], 0)); })
        .attr("height", function(d) { return Math.abs(y(0) - y(barData[instituteSelect][d])); })
        .attr("fill", function(d) { return partyColors(d)});
  }
  
  function drawInstituteLegend() {
    var iLegendGroup = svg.append("g");
    var iLegend = iLegendGroup.selectAll(".iLegend")
      .data(instituteList)
      .enter()
      .append("g")
      .attr("class", "iLegend")
      .attr("transform", function(d, i) { return "translate(" + (100 + i * 60) + ",20)"; });

    iLegend.append("circle")
      .attr("cx", 0)
      .attr("cy", 0)
      .attr("r", 10)
      .style("stroke", "black")
      .style("fill", function(d) {if(d == instituteSelect) return "black"; else return "white";})
      .on("click", function(d) {
        if(instituteSelect != d) {
          instituteSelect = d;

          focus.selectAll(".bar")
            .transition()
            .attr("y", function(d) { return y(Math.max(barData[instituteSelect][d], 0)); })
            .attr("height", function(d) { return Math.abs(y(0) - y(barData[instituteSelect][d])); });
          
          iLegend.select("circle").style("fill", function(dd) {if(dd == instituteSelect) return "black"; else return "white";});
        }
      });
  
    iLegend.append("text")
      .attr("x", 0)
      .attr("y", 20)
      .attr("text-anchor", "middle")
      .text(function(d) {return d;});
  }
  
  function drawAxes() {
    focus.append("g")
        .attr("class", "x axis")
        .attr("transform", "translate(0," + y(0) + ")")
        .call(xAxis);
  
    focus.append("g")
        .attr("class", "y axis")
        .call(yAxis)
      .append("text")
        .attr("transform", "rotate(-90)")
        .attr("y", -40)
        .attr("x", 0)
        .attr("dy", ".71em")
        .style("text-anchor", "end")
        .text("Verschiebung (%)");
  }

}
