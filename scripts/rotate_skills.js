{
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

	skills.style.height = `${maxHeight * 1.1}px`;

	skills.innerHTML = "";

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

		setTimeout(function() {
			skills.innerHTML = "";
			for(const skill of got) {
				const newSkill = skill.cloneNode(true)
				newSkill.classList.add("grow");
				skills.appendChild(newSkill);
			}
		}, 1000);
	}

	setInterval(rotate, 4000);
	rotate();
}
