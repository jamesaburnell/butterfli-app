var React = require('react');
var Link = require('react-router').Link

var Navbar = require('./Navbar.jsx');

var AccountHome = React.createClass({
	
	render(){

		if(this.props.dashes) {
			var key = 0;
			var dashList = this.props.dashes.map((element) => {
				key++;
				return (
					<li key={key} onClick={ () => {this.props.saveCurrentDash(element.id)} }>
						<Link to="DashHome">{element.title}</Link>
					</li>
				)
			})
		}
		
		return (
			<div>
				<Navbar username={this.props.username} currentDash={this.props.currentDash}/>
				<div>Sup, {this.props.username}! Account Home, fool!</div>
				<div>
					<ul>
						{dashList}
						<li><Link to='adddash'>Add Dash</Link></li>
					</ul>
				</div>
			</div>
		)
	}
})

module.exports = AccountHome;