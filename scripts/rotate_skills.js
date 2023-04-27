{
	const skillsToggle = document.getElementById("skills-toggle");

	const skills = document.querySelector("#skillslist");
	const skillNodes = Array.from(skills.children);

	function measureSkill(element) {
		const clone = element.cloneNode(true);
		clone.style.visibility = "hidden";
		clone.style.position = "absolute";
		skills.appendChild(clone);
		const r = {
			height: clone.offsetHeight,
			width: clone.offsetWidth,
		}
		clone.remove();
		return r;
	}

	let maxHeight = 0;

	for(const skill of skills.children) {
		maxHeight = Math.max(maxHeight, skill.offsetHeight);
	}

	skills.style.minHeight = `${maxHeight * 1.1}px`;

	let allSkills = false;

	skillsToggle.addEventListener("click", function() {
		allSkills = !allSkills;
		reset();
	});

	window.addEventListener("resize", function() {
		reset();
	})

	let intervalId;
	let timeoutId;

	function reset() {
		if(intervalId) {
			clearInterval(intervalId);
		}

		if(timeoutId) {
			clearTimeout(timeoutId);
		}

		skills.innerHTML = "";

		if(allSkills) {
			const choices = Array.from(skillNodes);
			while(choices.length > 0) {
				const index = Math.floor(Math.random() * choices.length);
				const choice = choices[index];
				skills.appendChild(choice.cloneNode(true));
				choices.splice(index, 1);
			}
		}
		else {
			function rotate() {
				const choices = Array.from(skillNodes);
				const got = [];
				let width = 0;
				let tries = 25;
				while(got.length < 10 && tries > 0) {
					tries--;
					const index = Math.floor(Math.random() * choices.length);
					const choice = choices[index];
					const choiceWidth = measureSkill(choice).width * 1.1;
					if(width + choiceWidth > skills.offsetWidth) {
						continue;
					}
					width += choiceWidth;
					got.push(choice);
					choices.splice(index, 1);
				}

				for(const skill of skills.children) {
					skill.classList.remove("grow");
					skill.classList.add("shrink");
				}

				function grow() {
					skills.innerHTML = "";
					for(const skill of got) {
						const newSkill = skill.cloneNode(true)
						newSkill.classList.add("grow");
						skills.appendChild(newSkill);
					}
				}

				if(skills.children.length > 0) {
					timeoutId = setTimeout(grow, 1000);
				}
				else {
					grow();
				}
			}

			intervalId = setInterval(rotate, 4000);
			rotate();
		}
	}

	reset();
}
