# Bulk Vote Wrapper Script

This is a wrapper script around [Martin's voting script](https://github.com/gitmachtl/scripts) to simplify generating **bulk votes** on **treasury withdrawal proposals**.

Place this script in the same directory as Martin's scripts, or ensure his scripts are accessible via your system's `$PATH`.

> ## ℹ️ Note
> **After uploading this, I realized you can simply run `24a_genVote.sh <drep> all "url: <url>"`. So this script isn't really needed anymore, just call the script directly with `all`. However, since the repository is already here, I'm leaving it as is. 😉**
> 
> **Also, the performance patch to cache SPO DRep delegation isn't necessary anymore. It's only fetched once when using `all`. You *can* still apply the patch if you want the script to run faster across multiple executions though.**
>

<br>

## 🚀 Usage

```bash
./bulkvote.sh <drep vkey file> <proposals json file> <optional rationale url>
```

### Arguments

* **`<drep vkey file>`**
  Your DRep verification key file. It **must end with `.drep.vkey`**; the extension might be omitted when calling the script.

* **`<proposals json file>`**
  A local JSON file containing treasury withdrawal proposals.

  > ✅ A sample file with the current 39 proposals is included with this script. This was fetched with the following command:
  > ````bash
  > echo "[" > proposals.json; first=1; for ((page=0;;page++)); do echo "Fetching page $page..." >&2; resp=$(curl -s "https://be.gov.tools/proposal/list?page=$page&pageSize=10&type[]=TreasuryWithdrawals"); items=$(echo "$resp" | jq -c '.elements[]'); [ -z "$items" ] && break; while IFS= read -r item; do [ $first -eq 0 ] && echo "," >> proposals.json; echo "$item" >> proposals.json; first=0; done <<< "$items"; done; echo "]" >> proposals.json
  > ````

* **`<optional rationale url>`**
  A **hosted URL** pointing to a **rationale JSON file in UTF-8** format.

  > 📎 This rationale will be used for **all** proposals.

### Example

```bash
./bulkvote.sh mykey.drep.vkey proposals.json https://example.org/rationale.json
```

> 🔸 After each vote, the script pauses and waits for you to press `ENTER`. This helps you follow the process without missing output.
> You can comment out this line in the script if you prefer automatic, uninterrupted voting.

## ⚡ Performance Tip – SPO DRep Delegation Caching

Fetching the **SPO DRep delegation** via Martin’s `24a_genVote.sh` can be slow on every run. To improve performance, you can cache the result for the current epoch.

### 🔧 Patch Instructions

In Martin’s script `24a_genVote.sh` (as of `Update-2025-10`), **replace lines 312–315**:

**Original:**

```bash
#Get new Pool Stake Distribution including default delgation, for quorum calculation later on - available with this command since cli 10.2.0.0
showProcessAnimation "Query Stakepool-Distribution Info: " &
poolStakeDistributionJSON=$(${cardanocli} ${cliEra} query spo-stake-distribution --all-spos 2> /dev/stdout)
if [ $? -ne 0 ]; then stopProcessAnimation; echo -e "\e[35mERROR - ${poolStakeDistributionJSON}\e[0m\n"; exit 1; else stopProcessAnimation; fi;
```

**Replace with:**

```bash
#Get new Pool Stake Distribution including default delgation, for quorum calculation later on - available with this command since cli 10.2.0.0
spoStakeDistCacheFile="cache-spo-stake-distribution.${currentEpoch}.json"
if [ -f "${spoStakeDistCacheFile}" ]; then
	echo "Use Stakepool-Distribution Info from cached file ${spoStakeDistCacheFile}"
	poolStakeDistributionJSON=$(cat "${spoStakeDistCacheFile}")
else
	showProcessAnimation "Query Stakepool-Distribution Info: " &
	poolStakeDistributionJSON=$(${cardanocli} ${cliEra} query spo-stake-distribution --all-spos 2> /dev/stdout)
	if [ $? -ne 0 ]; then
		stopProcessAnimation
		echo -e "\e[35mERROR - ${poolStakeDistributionJSON}\e[0m\n"
		exit 1
	else
		stopProcessAnimation
		echo "${poolStakeDistributionJSON}" > "${spoStakeDistCacheFile}"
	fi
fi
```

This will cache the distribution JSON for the **current epoch**.

> 📝 You can delete the file manually to refresh it, or modify the script to expire the cache sooner if desired.

## ⚠️ Disclaimer

This script is provided **as-is**, without warranty of any kind. Use it at your own risk and make sure you understand what each part does before executing it. Feel free to fork, extend, or suggest improvements!
