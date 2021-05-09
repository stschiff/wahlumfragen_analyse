function koalitionen_chart(svg) {
  var margin = {top: 10, right: 100, bottom: 100, left: 40},
      margin2 = {top: 430, right: 100, bottom: 20, left: 40},
      width = 960 - margin.left - margin.right,
      height = 500 - margin.top - margin.bottom,
      height2 = 500 - margin2.top - margin2.bottom;

  var legendPos = width + 60;

  var parseDate = d3.time.format("%d.%m.%Y").parse;
  var bisectDate = d3.bisector(function(d) { return d.date; }).left;

  var x = d3.time.scale().range([0, width]).domain([parseDate("27.09.2009"), parseDate("30.09.2013")]),
      x2 = d3.time.scale().range([0, width]).domain(x.domain()),
      y = d3.scale.linear().range([height, 0]).domain([0, 102]);

  var partyColors = d3.scale.ordinal()
      .domain(["ROTROTGRUEN", "SCHWARZGELB", "ROTGRUEN", "GROKO", "SCHWARZGRUEN"])
      .range(["purple", "#FFD300", "red", "black", "green"]);

  var xAxis = d3.svg.axis().scale(x).orient("bottom"),
      xAxis2 = d3.svg.axis().scale(x2).orient("bottom"),
      yAxis = d3.svg.axis().scale(y).orient("left");

  var brush = d3.svg.brush()
    .x(x2)
    .extent([parseDate("1.1.2012"), parseDate("30.09.2013")])
    .on("brush", brushed);

  var line = d3.svg.line()
    .x(function(d) {return x(d.date);})
    .y(function(d) {return y(d.val);});

  svg.attr("width", width + margin.left + margin.right)
      .attr("height", height + margin.top + margin.bottom);

  svg.append("defs").append("clipPath")
      .attr("id", "clip")
    .append("rect")
      .attr("width", width)
      .attr("height", height);

  var focus = svg.append("g")
      .attr("class", "focus")
      .attr("transform", "translate(" + margin.left + "," + margin.top + ")");
    
  var context = svg.append("g")
      .attr("class", "context")
      .attr("transform", "translate(" + margin2.left + "," + margin2.top + ")");

  var partyData;

  d3.tsv("data/coalitionProjections.txt", function(error, raw_data) {
    partyData = partyColors.domain().map(function(name) {
      return {
        name: name,
        values: raw_data.map(function(d) {
          return {
            date: parseDate(d.Date),
            val: +d[name] * 100
          };
        })
      };
    });

    drawPlots();
    drawHoverLine();
    drawLegend();
    drawBrush();
    drawAxes();
  });

  function drawPlots() {
    var plotGroup = focus.append("g");
    var plots = plotGroup.selectAll(".linePlot")
      .data(partyData)
      .enter()
      .append("path")
      .attr("class", "linePlot")
      .style("stroke", function(d) { return partyColors(d.name);})
      .attr("d", function(d) {return line(d.values);});
  }

  function drawHoverLine() {
    var hoverLine = focus.append("line")
      .attr("class", "hoverLine")
      .attr("y1", 0)
      .attr("y2", height);

    var hoverTextGroup = focus.append("g")
      .attr("id", "hoverTextGroup");
    hoverTextGroup.append("text")
      .attr("id", "hoverTextDate")
      .attr("x", 20)
      .attr("y", 5);
    hoverTextGroup.selectAll(".hoverTextPartyRange")
      .data(partyData)
      .enter()
      .append("text")
      .attr("class", "hoverTextPartyRange")
      .attr("x", 20)
      .attr("y", function(d, i) {return 5 + 12 * (i + 1);})
      .style("fill", function(d) {return partyColors(d.name)});

    focus.append("rect")
      .attr("class", "overlay")
      .attr("width", width)
      .attr("height", height)
      .on("mouseover", function() {
        hoverLine.style("display", null);
        hoverTextGroup.style("display", null);
      })
      .on("mouseout", function() {
        hoverLine.style("display", "none");
        hoverTextGroup.style("display", "none");
      })
      .on("mousemove", updateHover);
  }

  function updateHover() {
    var x0 = x.invert(d3.mouse(this)[0]);
    var hoverLine = focus.select(".hoverLine");
    var hoverTextGroup = focus.select("#hoverTextGroup");
  
    hoverLine.attr("x1", x(x0)).attr("x2", x(x0));
    hoverTextGroup.select("#hoverTextDate")
      .text(d3.time.format("%d. %b %Y")(x0));
    hoverTextGroup.selectAll(".hoverTextPartyRange")
      .text(function(d, j) {
        i = bisectDate(d.values, x0, 1);
        if(i < 1)
          i = 1;
        if(i >= d.values.length)
          i = d.values.length - 1;
        d0 = d.values[i - 1].date;
        d1 = d.values[i].date;
        i = x0 - d0.date > d1.date - x0 ? i : i - 1;
        return d.name + ": " + Math.round(d.values[i].val * 10)/10;
      });
  }

  function drawLegend() {
    var legendGroup = focus.append("g");
    var legend = legendGroup.selectAll(".legend")
      .data(partyColors.domain())
      .enter().append("g")
      .attr("class", "legend")
      .attr("transform", function(d, i) { return "translate(0," + i * 20 + ")"; });
  
    legend.append("rect")
      .attr("x", legendPos)
      .attr("width", 18)
      .attr("height", 18)
      .style("stroke", partyColors)
      .style("fill", function(d) {return partyColors(d);});

    legend.append("text")
      .attr("x", legendPos - 6)
      .attr("y", 9)
      .attr("dy", ".35em")
      .text(function(d) { return d; });

  }

  function drawBrush() {
    context.append("g")
      .attr("class", "x brush")
      .call(brush)
      .selectAll("rect")
      .attr("y", -6)
      .attr("height", height2 + 7);
  
    brushed();
  }

  function brushed() {
    x.domain(brush.empty() ? x2.domain() : brush.extent());
    focus.selectAll(".linePlot").attr("d", function(d) {return line(d.values);});
    focus.select(".x.axis").call(xAxis);
  }

  function drawAxes() {
    focus.append("g")
      .attr("class", "x axis")
      .attr("transform", "translate(0," + height + ")")
      .call(xAxis);

    focus.append("g")
      .attr("class", "y axis")
      .call(yAxis)
      .append("text")
      .attr("transform", "rotate(-90)")
      .attr("y", -40)
      .attr("x", -height+100)
      .attr("dy", ".71em")
      .style("text-anchor", "center")
      .text("Wahrscheinlichkeit Koalitionsmehrheit (%)");

    context.append("g")
      .attr("class", "x axis")
      .attr("transform", "translate(0," + height2 + ")")
      .call(xAxis2);
  }

}