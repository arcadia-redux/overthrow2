var pets = []
var currentPetIndex = null

function Pet( parent, data ) {
	var button = $.CreatePanel( "Button", parent, "" )
	button.AddClass( "Pet" )

	if ( data.image && data.index ) {
		var image = $.CreatePanel( "Image", button, "" )
		image.SetImage( "file://{images}/" + data.image + ".png" )

		button.SetPanelEvent( "onactivate", function() {
			GameEvents.SendCustomGameEventToServer( "cosmetics_select_pet", {
				index: data.index
			} )
		} )
	} else if ( data.styles ) {
		this.styles = data.styles
		this.style = 0

		this.styleImages = []

		for ( var i = 0; i < data.styles.length; i++ ) {
			this.styleImages[i] = $.CreatePanel( "Image", button, "" )
			this.styleImages[i].SetImage( "file://{images}/" + data.styles[i].image + ".png" )
			this.styleImages[i].visible = false
		}

		this.Scroll = function( v ) {
			this.styleImages[this.style].visible = false
			this.style = this.style + v

			if ( this.style == -1 ) {
				this.style = this.styles.length - 1
			} else if ( this.style == this.styles.length ) {
				this.style = 0
			}

			this.styleImages[this.style].visible = true
		}

		this.Scroll( 0 )

		var left_button = $.CreatePanel( "Button", button, "PetScrollLeft" )
		var right_button = $.CreatePanel( "Button", button, "PetScrollRight" )

		var a = this

		button.SetPanelEvent( "onactivate", function() {
			GameEvents.SendCustomGameEventToServer( "cosmetics_select_pet", {
				index: a.styles[a.style].index
			} )
		} )

		left_button.SetPanelEvent( "onactivate", function() {
			a.Scroll( -1 )
		} )
		right_button.SetPanelEvent( "onactivate", function() {
			a.Scroll( 1 )
		} )
	}
}

function CreatePets() {
	var container = $( "#PetsContainer" )
	container.RemoveAndDeleteChildren()

	for ( var data of petsData ) {
		pets.push( new Pet( container, data ) )
	}
}

function DeletePet() {
	GameEvents.SendCustomGameEventToServer( "cosmetics_remove_pet", {} )
}

function UpdateCurrentPet( index ) {
	if ( index ) {
		//var current = $( "#CurrentPetImage" )

		//for ( var data of petsData ) {
		//	if ( index == data.index ) {
		//		current.SetImage( "file://{images}/" + data.image + ".png" )
		//	} else if ( data.styles ) {
		//		for ( var style of data.styles ) {
		//			if ( index == style.index ) {
		//				current.SetImage( "file://{images}/" + style.image + ".png" )
		//			}
		//		}
		//	}
		//}

		//current.style.visibility = "visible"

		//$( "#PetNone" ).style.visibility = "collapse"
		$( "#DeletePet" ).style.visibility = "visible"
	} else {
		//$( "#PetNone" ).style.visibility = "visible"
		//$( "#CurrentPetImage" ).style.visibility = "collapse"
		$( "#DeletePet" ).style.visibility = "collapse"
	}
}

CreatePets()