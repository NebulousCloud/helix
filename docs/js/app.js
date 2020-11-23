
const skippedCategories = ["manual"];

class Node
{
	constructor(name, element, expandable, noAutoCollapse, children = [])
	{
		this.name = name;
		this.element = element;
		this.expandable = expandable;
		this.noAutoCollapse = noAutoCollapse;
		this.children = children;
	}

	AddChild(name, element, expandable, noAutoCollapse, children)
	{
		let newNode = new Node(name, element, expandable, noAutoCollapse, children);
		this.children.push(newNode);

		return newNode;
	}
}

class SearchManager
{
	constructor(input, contents)
	{
		this.input = input;
		this.input.addEventListener("input", event =>
		{
			this.OnInputUpdated(this.input.value.toLowerCase().replace(/:/g, "."));
		});

		// setup search tree
		this.tree = new Node("", document.createElement("null"), true, true);
		this.entries = {};

		const categoryElements = contents.querySelectorAll(".category");

		// iterate each kind (hooks/libraries/classes/etc)
		for (const category of categoryElements)
		{
			const nameElement = category.querySelector(":scope > summary > h2");

			if (!nameElement)
			{
				continue;
			}

			const categoryName = nameElement.textContent.trim().toLowerCase();

			if (skippedCategories.includes(categoryName))
			{
				continue;
			}

			let categoryNode = this.tree.AddChild(categoryName, category, true, true);
			const sectionElements = category.querySelectorAll(":scope > ul > li");

			for (const section of sectionElements)
			{
				const entryElements = section.querySelectorAll(":scope > details > ul > li > a");
				const sectionName = section.querySelector(":scope > details > summary > a")
					.textContent
					.trim()
					.toLowerCase();

				let sectionNode = categoryNode.AddChild(sectionName, section.querySelector(":scope > details"), true);

				for (let i = 0; i < entryElements.length; i++)
				{
					const entryElement = entryElements[i];
					const entryName = entryElement.textContent.trim().toLowerCase();

					sectionNode.AddChild(sectionName + "." + entryName, entryElement.parentElement);
				}
			}
		}
	}

	ResetVisibility(current)
	{
		current.element.style.display = "";

		if (current.noAutoCollapse)
		{
			current.element.open = true;
		}
		else if (current.expandable)
		{
			current.element.open = false;
		}

		for (let node of current.children)
		{
			this.ResetVisibility(node);
		}
	}

	Search(input, current)
	{
		let matched = false;

		if (current.name.indexOf(input) != -1)
		{
			matched = true;
		}

		for (let node of current.children)
		{
			let childMatched = this.Search(input, node);
			matched = matched || childMatched;
		}

		if (matched)
		{
			current.element.style.display = "";

			if (current.expandable)
			{
				current.element.open = true;
			}
		}
		else
		{
			current.element.style.display = "none";

			if (current.expandable)
			{
				current.element.open = false;
			}
		}

		return matched;
	}

	OnInputUpdated(input)
	{
		if (input.length <= 1)
		{
			this.ResetVisibility(this.tree);
			return;
		}

		this.Search(input, this.tree);
	}
}

window.onload = function()
{
	const openDetails = document.querySelector(".category > ul > li > details[open]");

	if (openDetails)
	{
		openDetails.scrollIntoView();
	}
}

document.addEventListener("DOMContentLoaded", function()
{
	const searchInput = document.getElementById("search");
	const contents = document.querySelector("body > main > nav > section");

	if (searchInput && contents)
	{
		new SearchManager(searchInput, contents);
	}
});
